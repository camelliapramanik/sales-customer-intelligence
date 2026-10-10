# SQL analytics pipeline

Target database: `AdventureWorks2025` (the OLTP sample). Execute each file as a whole in SSMS, or use `sqlcmd` with `-b` to fail on SQL errors. `GO` is a client batch separator.

| Order | File | Responsibility | Writes |
| --- | --- | --- | --- |
| Optional | [01_Data_Exploration.sql](01_Data_Exploration.sql) | Profile dates, sales grain, customer types, channel assignment, categories, and historical cost | None |
| 1 | [02_Analytics_Schema_and_Date.sql](02_Analytics_Schema_and_Date.sql) | Create schema/date table and insert missing order-range dates | `analytics` schema, `analytics.DimDate` |
| 2 | [03_Dimension_Views.sql](03_Dimension_Views.sql) | Publish Customer, Product, Territory, SalesPerson, and Date views | Five views |
| 3 | [04_Fact_Sales_View.sql](04_Fact_Sales_View.sql) | Publish line-item sales with as-of standard costs | `analytics.vw_FactSales` |
| 4 | [05_Data_Validation.sql](05_Data_Validation.sql) | Check grain, dimension coverage, dates, rounding, and cost coverage | None |

## Execution and reruns

Run from an account permitted to create the analytics schema/table/views and read the source tables. Power BI refresh only needs read access to the analytics views.

The date script preserves existing dates and inserts missing ones. Views use `CREATE OR ALTER`; reruns replace their definitions. No script drops a table or changes AdventureWorks source records. Run one build at a time. Existing date-table schemas or previously incorrect date labels are not migrated automatically.

The scripts use the original report's observed order-date bounds rather than full calendar years. English month/day labels and Sunday-first weekday numbering are explicit. Switching to a full-year calendar would change the maximum calendar date and therefore customer activity measures unless their analysis-date logic were adjusted as well.

## Consolidation decisions

The original working script mixed exploration with repeated builds. The curated pipeline retains the **last** definition of each view, including historical cost in the fact view. Superseded current-cost fact views, repeated previews, and the earlier person-first customer classification were removed from the published workflow.

The exploratory source file was reorganized into purposeful read-only questions. Date creation was changed from drop/recreate to insert-missing behavior. Fact and dimension output names and business expressions were preserved for PBIX compatibility.

## Reading validation results

Structural checks must return `PASS`; failures raise error 50002. The final totals should be compared against [the PBIX snapshot](../docs/metadata/snapshot.json), allowing for differences if the source data has changed.

The cost diagnostic returns counts of rows using the current-cost fallback or a historical cost beyond its recorded end date. Review these before interpreting profit. They are not silently excluded because that would change the original methodology.

Scripts were reviewed statically during preparation; no SQL Server execution is claimed. [Validation record](../docs/VALIDATION.md)
