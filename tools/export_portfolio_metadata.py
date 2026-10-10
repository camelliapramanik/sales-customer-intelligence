"""Export reviewable documentation from the supplied PBIX without modifying it.

Run from the repository root after installing tools/requirements.txt.
No SQL connection or Power BI service access is required.
Only aggregated sample data is exported; no customer-level records are written.
"""
from pathlib import Path
from decimal import Decimal
import hashlib
import json
import zipfile

from pbixray import PBIXRay

ROOT = Path(__file__).resolve().parents[1]
PBIX = ROOT / "Power BI" / "Sales_Customer_Intelligence.pbix"
OUT = ROOT / "docs" / "metadata"
TABLES = ["DimCustomer", "DimDate", "DimProduct", "DimSalesPerson", "DimTerritory", "FactSales"]


def save_json(name, value):
    (OUT / name).write_text(json.dumps(value, indent=2, default=str) + "\n", encoding="utf-8")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    dax_dir = ROOT / "DAX"
    query_dir = ROOT / "Power BI" / "Power Query"
    dax_dir.mkdir(exist_ok=True)
    query_dir.mkdir(exist_ok=True)
    with PBIXRay(str(PBIX)) as model:
        measures = model.dax_measures.to_dict("records")
        save_json("measures.json", measures)
        save_json("relationships.json", model.relationships.to_dict("records"))
        schema = model.schema
        save_json("schema.json", schema[schema.TableName.isin(TABLES)].to_dict("records"))
        dax = ["// Extracted verbatim from the PBIX. Reference catalog, not a DAX query.",
               "// Create each measure separately in its original _Measures table.",
               "// Diagnostic measures are retained to keep this export faithful.\n"]
        for row in measures:
            name = row.get("Name", row.get("MeasureName"))
            dax += [f"// Table: {row['TableName']}", f"{name} =", row["Expression"].strip(), ""]
        (dax_dir / "Measures.dax").write_text("\n".join(dax), encoding="utf-8")
        for row in model.power_query.to_dict("records"):
            (query_dir / f"{row['TableName']}.m").write_text(row["Expression"] + "\n", encoding="utf-8")

        frames = {name: model.get_table(name) for name in TABLES}
        fact = frames["FactSales"]
        sales = float(fact.SalesAmount.sum())
        profit = float(fact.Profit.sum())
        snapshot = {
            "source": PBIX.name,
            "pbix_sha256": hashlib.sha256(PBIX.read_bytes()).hexdigest(),
            "scope": "Embedded imported data, all rows, no report filters; Python aggregates, not DAX engine output.",
            "table_rows": {n: len(df) for n, df in frames.items()},
            "measure_count": len(measures),
            "order_date_min": str(fact.OrderDate.min()),
            "order_date_max": str(fact.OrderDate.max()),
            "orders": int(fact.SalesOrderID.nunique()),
            "customers": int(fact.CustomerID.nunique()),
            "products": int(fact.ProductID.nunique()),
            "quantity": int(fact.OrderQty.sum()),
            "sales": round(sales, 2),
            "cost": round(float(fact.TotalProductCost.sum()), 2),
            "profit": round(profit, 2),
            "profit_margin": profit / sales,
            "average_order_value": sales / fact.SalesOrderID.nunique(),
        }
        for dimension, key, label in [("DimProduct", "ProductID", "ProductCategory"),
                                      ("DimTerritory", "TerritoryID", "TerritoryName")]:
            joined = fact.merge(frames[dimension][[key, label]], on=key, validate="many_to_one")
            grouped = joined.groupby(label)[["SalesAmount", "Profit"]].sum().round(2)
            snapshot[label] = grouped.sort_values("SalesAmount", ascending=False).reset_index().to_dict("records")
        snapshot["SalesChannel"] = fact.groupby("SalesChannel")[["SalesAmount", "Profit"]].sum().round(2).reset_index().to_dict("records")
        last = fact.groupby("CustomerID").OrderDate.max()
        as_of = frames["DimDate"].FullDate.max()
        snapshot["customer_activity"] = {
            "as_of": str(as_of),
            "active_within_90_days": int(((as_of - last).dt.days <= 90).sum()),
            "inactive_over_90_days": int(((as_of - last).dt.days > 90).sum()),
            "repeat_customers": int((fact.groupby("CustomerID").SalesOrderID.nunique() > 1).sum()),
        }
        checks = {"duplicate_sales_detail_ids": int(fact.SalesOrderDetailID.duplicated().sum())}
        for dimension, fact_key, dim_key in [
            ("DimCustomer", "CustomerID", "CustomerID"), ("DimProduct", "ProductID", "ProductID"),
            ("DimSalesPerson", "SalesPersonID", "SalesPersonID"), ("DimTerritory", "TerritoryID", "TerritoryID"),
            ("DimDate", "OrderDateKey", "DateKey")]:
            checks[f"duplicate_keys_{dimension}"] = int(frames[dimension][dim_key].duplicated().sum())
            checks[f"unmatched_rows_{dimension}"] = int((~fact[fact_key].isin(frames[dimension][dim_key])).sum())
        checks["duplicate_customer_names"] = int(frames["DimCustomer"].CustomerName.duplicated().sum())
        dates = frames["DimDate"].FullDate
        checks["missing_calendar_days"] = int((dates.max() - dates.min()).days + 1 - dates.nunique())
        residual = fact.SalesAmount - fact.TotalProductCost - fact.Profit
        checks["profit_reconciliation_rows_over_one_cent"] = int(sum(abs(x) > Decimal("0.01") for x in residual))
        save_json("snapshot.json", snapshot)
        save_json("data_checks.json", checks)

    with zipfile.ZipFile(PBIX) as archive:
        pages = []
        for page_id in json.loads(archive.read("Report/definition/pages/pages.json"))["pageOrder"]:
            prefix = f"Report/definition/pages/{page_id}/"
            page = json.loads(archive.read(prefix + "page.json"))
            visuals = []
            for path in archive.namelist():
                if not (path.startswith(prefix) and path.endswith("/visual.json")):
                    continue
                obj = json.loads(archive.read(path))
                visual = obj.get("visual", {})
                fields = []
                for role in visual.get("query", {}).get("queryState", {}).values():
                    for projection in role.get("projections", []):
                        field = projection.get("field", {})
                        for kind in ("Column", "Measure"):
                            if kind in field:
                                term = field[kind]
                                fields.append(term["Expression"]["SourceRef"].get("Entity", "") + "." + term["Property"])
                titles = visual.get("visualContainerObjects", {}).get("title", [])
                title = next((x.get("properties", {}).get("text", {}).get("expr", {}).get("Literal", {}).get("Value", "") for x in titles), "")
                visuals.append({"type": visual.get("visualType"), "title": title.strip("'"), "fields": fields})
            pages.append({"name": page["displayName"], "visibility": page.get("visibility", "Visible"), "visuals": visuals})
        save_json("report_pages.json", pages)
    print(f"Exported {len(measures)} measures, {len(pages)} pages, and verified snapshot to {OUT}")


if __name__ == "__main__":
    main()
