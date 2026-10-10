# Data model and dictionary

## Model grain and sources

The report imports six analytics views into one fact table and five dimensions. `_Measures` is a separate measure container. The package also contains Power BI auto-generated date tables; they are not additional business dimensions in the core star schema.

| Model table | SQL view | Grain | Imported rows |
| --- | --- | --- | ---: |
| FactSales | analytics.vw_FactSales | One sales order detail | 121,317 |
| DimCustomer | analytics.vw_DimCustomer | One customer with an order | 19,119 |
| DimProduct | analytics.vw_DimProduct | One sold product | 266 |
| DimTerritory | analytics.vw_DimTerritory | One territory | 10 |
| DimSalesPerson | analytics.vw_DimSalesPerson | One salesperson plus unassigned member | 18 |
| DimDate | analytics.vw_DimDate | One calendar day in the observed range | 1,127 |

The salesperson count includes 17 source people and synthetic key `-1`. Product and customer dimensions are activity-based subsets of the source, so they do not represent the entire product catalog or every registered account.

## Verified active relationships

| Fact key (many side) | Dimension key (one side) | Filter direction |
| --- | --- | --- |
| FactSales.CustomerID | DimCustomer.CustomerID | Dimension → fact |
| FactSales.ProductID | DimProduct.ProductID | Dimension → fact |
| FactSales.TerritoryID | DimTerritory.TerritoryID | Dimension → fact |
| FactSales.SalesPersonID | DimSalesPerson.SalesPersonID | Dimension → fact |
| FactSales.OrderDateKey | DimDate.DateKey | Dimension → fact |

All five relationships are active. Customer territory attributes do not create an additional dimension-to-dimension relationship. DueDate and ShipDate do not participate in these five relationships. See the [extracted relationship metadata](metadata/relationships.json).

## Transformation decisions

- SalesOrderHeader supplies dates, customer, territory, salesperson, and channel flag; SalesOrderDetail supplies the line grain, quantity, price, discount, and revenue.
- Product supplies descriptive attributes and fallback current cost. ProductCostHistory is searched using the latest StartDate on or before OrderDate, retaining the final original SQL behavior.
- Customer classification checks StoreID before PersonID to avoid treating a store's contact as an individual account.
- A salesperson key of `-1` preserves unassigned transactions in the model. It does not independently determine whether an order is Online or Reseller.
- Power Query converts monetary fact fields to Currency.Type and quantity/customer ID to integer types where explicitly specified. The extracted M queries retain the original localhost source.
- The date setup uses the source order range and does not drop the existing table. On the stored sample it spans 1,127 consecutive days.

## Column dictionary

Types below are the **decoded model types** reported by the inspection library, not SQL Server DDL declarations. The SQL source specifies decimal precision where relevant; Power Query adds its own model conversions.

### FactSales

| Column | Decoded model type | Meaning |
| --- | --- | --- |
| `SalesOrderDetailID` | `Int64` | Unique sales line identifier; the fact-table grain. |
| `SalesOrderID` | `Int64` | Order identifier; repeats for multi-line orders. |
| `OrderDateKey` | `Int64` | YYYYMMDD key linking to DimDate.DateKey. |
| `OrderDate` | `datetime64[ns]` | Order date, cast to date in SQL. |
| `DueDate` | `datetime64[ns]` | Expected due date; not the active reporting date relationship. |
| `ShipDate` | `datetime64[ns]` | Shipping date; not the active reporting date relationship. |
| `CustomerID` | `Int64` | Customer account key; use this instead of name to identify an account. |
| `SalesPersonID` | `Int64` | Source salesperson key, or -1 for no assigned salesperson. |
| `TerritoryID` | `Int64` | Territory key. In the customer dimension this is an attribute; FactSales territory drives the active relationship. |
| `ProductID` | `Int64` | Source product key; dimension includes sold products only. |
| `SalesChannel` | `string` | Online when OnlineOrderFlag = 1; otherwise Reseller. |
| `OrderQty` | `Int64` | Quantity ordered on the line. |
| `UnitPrice` | `decimal.Decimal` | Transaction unit price before discount. |
| `UnitPriceDiscount` | `decimal.Decimal` | Source line discount fraction. |
| `GrossSales` | `decimal.Decimal` | UnitPrice × OrderQty, SQL decimal(18,2). |
| `DiscountAmount` | `decimal.Decimal` | Gross unrounded line value − LineTotal, SQL decimal(18,2). |
| `SalesAmount` | `decimal.Decimal` | Discounted LineTotal, SQL decimal(18,2); excludes order tax/freight. |
| `TotalProductCost` | `decimal.Decimal` | Selected standard cost × quantity, SQL decimal(18,2). |
| `Profit` | `decimal.Decimal` | Unrounded LineTotal − selected cost × quantity, then SQL decimal(18,2). |
| `UnitStandardCost` | `Float64` | As-of standard cost with current-cost fallback, SQL decimal(18,4). |

### DimCustomer

| Column | Decoded model type | Meaning |
| --- | --- | --- |
| `CustomerID` | `Int64` | Customer account key; use this instead of name to identify an account. |
| `AccountNumber` | `string` | Source customer account reference. |
| `CustomerType` | `string` | Store, Individual, or Unknown; StoreID takes precedence. |
| `CustomerName` | `string` | Store name or person full name; not guaranteed unique. |
| `TerritoryID` | `Int64` | Territory key. In the customer dimension this is an attribute; FactSales territory drives the active relationship. |
| `TerritoryName` | `string` | Readable territory name. |
| `CountryRegionCode` | `string` | Source country/region code. |
| `TerritoryGroup` | `string` | Regional grouping from SalesTerritory. |

### DimProduct

| Column | Decoded model type | Meaning |
| --- | --- | --- |
| `ProductID` | `Int64` | Source product key; dimension includes sold products only. |
| `ProductName` | `string` | Readable product name. |
| `ProductNumber` | `string` | Source product identifier. |
| `Color` | `string` | Color, with Not Specified used for null values. |
| `StandardCost` | `decimal.Decimal` | Current catalog standard cost; historical fact cost is selected separately. |
| `ListPrice` | `decimal.Decimal` | Current catalog list price, not necessarily the transaction selling price. |
| `Size` | `string` | Size, with Not Specified used for null values. |
| `ProductSubcategory` | `string` | Product subcategory; source nulls are retained. |
| `ProductCategory` | `string` | Product category; source nulls are retained. |

### DimTerritory

| Column | Decoded model type | Meaning |
| --- | --- | --- |
| `TerritoryID` | `Int64` | Territory key. In the customer dimension this is an attribute; FactSales territory drives the active relationship. |
| `TerritoryName` | `string` | Readable territory name. |
| `CountryRegionCode` | `string` | Source country/region code. |
| `TerritoryGroup` | `string` | Regional grouping from SalesTerritory. |

### DimSalesPerson

| Column | Decoded model type | Meaning |
| --- | --- | --- |
| `SalesPersonID` | `Int64` | Source salesperson key, or -1 for no assigned salesperson. |
| `SalesPersonName` | `string` | Person full name; -1 is labelled Online / No Salesperson. |
| `SalesQuota` | `decimal.Decimal` | Source salesperson quota; null for the synthetic member. |
| `Bonus` | `decimal.Decimal` | Source bonus; zero for the synthetic member. |
| `CommissionPct` | `decimal.Decimal` | Source commission percentage; zero for the synthetic member. |

### DimDate

| Column | Decoded model type | Meaning |
| --- | --- | --- |
| `DateKey` | `Int64` | Integer date key in YYYYMMDD form. |
| `FullDate` | `datetime64[ns]` | Continuous calendar date within the observed order range. |
| `CalendarYear` | `Int64` | Calendar year. |
| `QuarterNumber` | `Int64` | Quarter number, 1–4. |
| `QuarterName` | `string` | Quarter display label, Q1–Q4. |
| `MonthNumber` | `Int64` | Month number, 1–12. |
| `MonthName` | `string` | English month name. |
| `MonthShortName` | `string` | Three-letter month name. |
| `YearMonth` | `string` | Year-month label in YYYY-MM form. |
| `DayOfMonth` | `Int64` | Calendar day number. |
| `DayName` | `string` | English weekday name. |
| `DayOfWeek` | `Int64` | Weekday number; setup script explicitly uses Sunday = 1. |

