# Validation record and limitations

Repository preparation inspected the supplied PBIX archive, embedded model, imported records, visual field bindings, Power Query expressions, and the original SQL. The PBIX itself was not modified.

## Verified from the embedded data

| Check | Result |
| --- | --- |
| Report inventory | 4 visible analytical pages + 1 hidden About page |
| Measures | 55 in `_Measures` |
| Model relationships | 5 active, single-direction, many-to-one fact-to-dimension relationships |
| Fact grain | 121,317 rows; no duplicate SalesOrderDetailID values |
| Dimension keys | No duplicates across the five dimensions |
| Dimension coverage | No unmatched fact keys for date, customer, product, territory, or salesperson |
| Reporting dates | May 30, 2022 – June 29, 2025 |
| Date rows | 1,127 |
| Calendar continuity | No missing days within the observed date range |
| Profit line reconciliation | No residual greater than 0.01 in absolute value |
| Visual measure references | All 29 distinct bound measures resolve to the extracted catalog |
| Customer display names | 19,119 IDs but 19,103 distinct names; 16 duplicate name occurrences |

See [data_checks.json](metadata/data_checks.json), [relationships.json](metadata/relationships.json), and [snapshot.json](metadata/snapshot.json). Aggregates were computed in Python from imported PBIX tables, not through a DAX execution engine. Customer activity figures reproduce the unfiltered as-of rule; slicer-specific behavior was inspected in DAX, not interactively executed.

## SQL review

The final original definitions of all six views were preserved, with formatting and comments added. Duplicate draft definitions were removed. The date setup now creates the table if absent and inserts missing dates instead of dropping/recreating it. Source data is never modified.

`05_Data_Validation.sql` checks row counts, unique keys, orphan references, date continuity/key alignment, and line-level profit reconciliation. It also produces rounded-sales reconciliation and historical-cost coverage diagnostics. It is intended to run before refresh.

**Not executed here:** SQL Server restore/build/validation, Power BI refresh, DAX engine evaluation, or Desktop visual rendering. No SQL Server connection was used during preparation. A clean SQL execution and Desktop review remain the appropriate verification when refreshing or changing the report.

## Interpretation limits

1. **Profit is an estimate.** Historical standard cost is selected by latest StartDate ≤ OrderDate; EndDate is not enforced. Current product cost is the fallback. Strong channel margin differences should prompt review of mix, pricing, and cost coverage before drawing operational conclusions.
2. **Rounding is independent.** SQL rounds revenue, cost, and profit per line. In the stored snapshot, Sales − Cost is 12,557,699.99 while summed Profit is 12,557,724.05, a difference of 24.06 across 121,317 lines. The DAX measure sums the stored Profit column.
3. **Customer names are not account keys.** Name-only visual groupings may merge different CustomerIDs. A future report revision should include CustomerID or a unique ID/name label in customer rankings and tables.
4. **Recency is historical and filter-sensitive.** Analysis Date is the selected maximum date. The 90-day rule is a project convention, not a validated churn model. Customer lifetime/first-purchase measures retain non-date filters.
5. **Date coverage is partial.** The first and last years are incomplete. Extending the date table requires revisiting Analysis Date, otherwise customer activity may be measured beyond the last transaction.
6. **Contribution and rank depend on selection.** Product contribution removes only the name filter; other product attributes remain. YoY visuals use the comparable measure directly and default to the latest selected year.

## Optional report improvements

- Use a unique customer ID/name label in customer visuals and add a blank-purchase guard to Customer Status.
- Align the product contribution denominator with the intended “share of selected products” meaning when category/subcategory fields are in a detail table.
- Review the salesperson average's numerator/denominator under unusual channel filters.
- Hide diagnostic measures and consolidate the duplicate quantity measures after dependency review.
- Remove unused customer TopN filter declarations found on product and salesperson detail tables; these declarations have no populated filter expression in the inspected report definition.
- Review auto-generated date tables alongside the explicit DimDate before disabling Auto date/time; do not remove them without checking dependencies.
- Export genuine report screenshots or a PDF from Desktop for a future visual gallery.

These are documented improvement opportunities, not changes applied to the PBIX in this repository preparation.
