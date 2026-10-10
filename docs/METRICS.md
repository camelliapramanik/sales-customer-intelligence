# Metric definitions and DAX behavior

All **55 measures** were extracted from the PBIX's `_Measures` table. [Measures.dax](../DAX/Measures.dax) contains their original expressions; [measures.json](metadata/measures.json) preserves the extracted metadata. The DAX file is a readable catalog, not a runnable multi-measure query. Diagnostic and duplicate measures are retained to document the actual artifact.

## Sales and profitability

| Measure | Definition and interpretation |
| --- | --- |
| Total Sales | Sum of `FactSales[SalesAmount]`: discounted line revenue, excluding order tax/freight. |
| Total Cost | Sum of estimated standard product cost × quantity, rounded per line in SQL. |
| Total Profit | Sum of the SQL `Profit` column; not recalculated as Total Sales − Total Cost in DAX. |
| Profit Margin % | Total Profit / Total Sales; zero when the denominator is zero. |
| Total Orders | Distinct sales order IDs in the filtered fact table. |
| Total Customers | Distinct purchasing customer IDs in the filtered fact table. |
| Total Products | Distinct sold product IDs in the filtered fact table. |
| Total Quantity / Total Quantity Sold | Both sum `OrderQty`; the second name is used on the product page. |
| Average Order Value | Total Sales / Total Orders. |
| Gross Sales | Sum of unit price × quantity before discount, rounded per line. |
| Discount Amount | Sum of gross line value minus discounted line value, rounded per line. |
| Discount Rate % | Discount Amount / Gross Sales. This is a value-weighted rate. |
| Avg Selling Price | Total Sales / Total Quantity Sold. |

Profit uses the latest cost-history start date at or before an order date, falling back to the current product standard cost. The query does not enforce the history row's EndDate. It does not include operating expenses or calculate accounting net income. Three independently rounded columns can differ by one cent per line; therefore total profit and total sales minus total cost can differ slightly.

## Time intelligence

| Measure | Behavior |
| --- | --- |
| Sales LY | Uses `SAMEPERIODLASTYEAR(DimDate[FullDate])`. |
| Sales YTD / Sales MTD | Use `TOTALYTD` / `TOTALMTD` over the date dimension. |
| Sales Rolling 30D | Uses `DATESINPERIOD` ending at the maximum selected FullDate. |
| Sales YoY % Comparable | Determines overlapping available periods for a selected year and prior year, shifts boundaries with `EDATE`, and compares sales. |
| Sales YoY % Display | Returns the comparable measure only when one calendar year is selected. This wrapper is not the measure bound to the report's YoY visuals. |

`Sales YoY % Comparable` defaults to the **maximum selected year** when there is no single-year selection. It removes date filters to calculate comparison windows but retains other business filters; available start/end dates can therefore vary by territory or product. It returns blank when there is no supported prior-year comparison. The report uses this measure directly, so an all-years view is not an all-years growth calculation.

The date dimension contains the observed order range, not complete first/last calendar years. Validate changes to date-table bounds and time intelligence together.

## Customer analytics

| Measure | Definition and filter context |
| --- | --- |
| Analysis Date | `MAX(DimDate[FullDate])`; no dependency on today's date. |
| Customer First Purchase Date | First purchase through Analysis Date, replacing date filters. |
| Customer Last Purchase Date | Latest purchase through Analysis Date, replacing date filters. |
| Days Since Last Purchase | Days between last purchase and Analysis Date; blank if no last purchase. |
| Customer Base | Distinct purchasing customers through Analysis Date. |
| Active Customers | Customers in that base whose last purchase is **≤ 90 days** before Analysis Date. |
| Inactive Customers | Customers in that base whose last purchase is **> 90 days** before Analysis Date. |
| Active Customer Rate | Active Customers / Customer Base. |
| Repeat Customers | Customers with more than one distinct order through Analysis Date. |
| Repeat Customer Rate | Repeat Customers / Customer Base. |
| Avg Sales per Customer | Current-period Total Sales / current-period Total Customers. |
| Customer Lifetime Sales / Orders | Sales/orders accumulated through Analysis Date. |
| New Customers | Customers whose first purchase falls within the selected date interval. |
| Customer Status | Inactive when Days Since Last Purchase > 90, otherwise Active. |
| Customer Rank | Descending dense rank by lifetime sales across `ALLSELECTED(DimCustomer)`. |

These calculations remove **date filters only** where specified. Channel, territory, customer-type, and other remaining filters still apply. Consequently, “lifetime” and “new” are relative to the retained business context rather than necessarily a customer's entire cross-channel history.

The four customer display measures—last purchase date, days since purchase, status, and rank—use `ISINSCOPE(CustomerName)` to hide totals. The underlying status measure has no explicit blank-purchase guard: an account with a blank recency value can be labelled Active. Review that behavior before expanding the customer table to include non-purchasing accounts.

## Product and salesperson comparisons

| Measure | Behavior |
| --- | --- |
| Product Sales Contribution % | Sales divided by selected sales after applying `ALLSELECTED` to ProductName only. Other product attributes can still filter the denominator. |
| Product Rank | Dense rank by sales across the selected product dimension; blank outside product-name scope. |
| Product Profit Rank | Dense rank by profit over the selected product ID set. |
| Product Rank Display / Product Contribution Display | Hide results outside product-name scope. |
| Active Salespeople | Distinct fact-table salesperson IDs excluding `-1`. “Active” here means having filtered sales, not a 90-day rule. |
| Reseller Sales / Orders / Profit | Replace the channel filter with `SalesChannel = "Reseller"`. |
| Avg Sales per Salesperson | Reseller Sales / Active Salespeople. The numerator forces Reseller; the denominator retains its own current context. |
| Salesperson Rank | Dense sales rank across selected salespeople excluding `-1`, shown at salesperson-name scope. |
| Salesperson Sales Contribution % | Sales share of selected assigned salespeople; excludes `-1` from the denominator. |

## Diagnostic measures

`Selected Year Test`, `Current Sales Test`, and `Previous Year Sales Test` are present in the model. They are not bound to report visuals in the extracted inventory. They remain in the source export for fidelity and can be hidden or removed in a future Desktop cleanup after checking dependencies.
