# Reproduce the project

## Prerequisites

- Windows with a current Power BI Desktop release compatible with the supplied PBIX.
- SQL Server compatible with the AdventureWorks2025 backup, and SSMS or `sqlcmd`.
- Permissions to restore the sample and create schema/table/view objects.

The report package identifies its originating release as **2026.09**. If an older Desktop version cannot open it, use a compatible newer version. Python is optional and only needed to regenerate the documentation exports.

## 1. Restore the sample

Download the OLTP backup using [Microsoft's AdventureWorks instructions](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure). Restore it as `AdventureWorks2025` on your SQL Server instance. Choose valid local data/log paths in the restore dialog. The backup is intentionally excluded from this repository.

## 2. Build the SQL layer

Open and execute the following complete files in SSMS, in order:

1. `SQL/02_Analytics_Schema_and_Date.sql`
2. `SQL/03_Dimension_Views.sql`
3. `SQL/04_Fact_Sales_View.sql`
4. `SQL/05_Data_Validation.sql`

For a command-line build, this PowerShell example uses Windows authentication. Replace the server with your instance. Each call stops the workflow on a SQL error:

```powershell
$sqlInstance = 'localhost'
$buildScripts = @(
    'SQL/02_Analytics_Schema_and_Date.sql',
    'SQL/03_Dimension_Views.sql',
    'SQL/04_Fact_Sales_View.sql',
    'SQL/05_Data_Validation.sql'
)
foreach ($script in $buildScripts) {
    sqlcmd -S $sqlInstance -E -d AdventureWorks2025 -b -i $script
    if ($LASTEXITCODE -ne 0) { throw "SQL build failed: $script" }
}
```

Do not embed passwords in scripts. Configure authentication and trust settings for your local SQL Server environment.

## 3. Open and refresh Power BI

Open `Power BI/Sales_Customer_Intelligence.pbix`. The report contains imported data, so its saved contents can be inspected without first rebuilding SQL.

For refresh, open **Transform data → Data source settings**, select the SQL connection, and change `localhost` to your SQL instance where supported. Authenticate locally. If changing the connection there is unavailable, edit the `Sql.Databases("localhost")` source step in each of the six source queries through Power Query's Advanced Editor. Keep the `AdventureWorks2025` database navigation and `analytics` view names, unless you deliberately renamed the database.

| SQL object | Existing Power BI table |
| --- | --- |
| `analytics.vw_FactSales` | `FactSales` |
| `analytics.vw_DimCustomer` | `DimCustomer` |
| `analytics.vw_DimDate` | `DimDate` |
| `analytics.vw_DimProduct` | `DimProduct` |
| `analytics.vw_DimSalesPerson` | `DimSalesPerson` |
| `analytics.vw_DimTerritory` | `DimTerritory` |

Refresh the **existing** queries. Importing another set of tables would break the intended connection between visuals, measures, and model names. The `_Measures` table is a local measure container, not a SQL view. Extracted query text is available in [Power Query](../Power%20BI/Power%20Query).

## 4. Verify the refreshed model

Clear report selections. Check the expected five active relationships and compare the unfiltered totals with [snapshot.json](metadata/snapshot.json). On an unchanged source, expect 121,317 fact rows, 31,465 orders, 19,119 customers, 266 sold products, and sales of 109,846,380.90.

Check both date slicer behavior and customer activity as of June 29, 2025. For YoY comparisons, select one year explicitly. Inspect all four visible pages and the About page in Desktop before making a new release.

## Optional: regenerate documentation

The exporter reads the PBIX locally without changing it or connecting to SQL Server. From the repository root:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r tools/requirements.txt
.\.venv\Scripts\python.exe tools/export_portfolio_metadata.py
```

This updates DAX, M, schema, relationships, report inventory, reference aggregates, checks, and the PBIX hash. Handwritten narrative and the banner are not regenerated: review their figures if the report changes. Python results verify imported data; they do not execute the DAX engine or render report visuals.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Backup will not restore | Confirm database engine compatibility and valid data/log locations. |
| `analytics` object missing | Run scripts 02–04 against the same database used by Power Query. |
| Connection or credential error | Check the SQL instance, database access, and local data-source credentials. |
| New totals differ from the reference | Check source changes, refresh completion, filters, and the final historical-cost view. |
| YoY is blank for the earliest year | The measure cannot compare against a year before the available data. |
| Customer status differs from today's expectation | Recency is relative to the selected report date, not today. |
