/*
03_Dimension_Views.sql
Purpose: publish the five dimensions consumed by Power BI.
Prerequisite: run 02_Analytics_Schema_and_Date.sql in AdventureWorks2025.
Rerun behavior: CREATE OR ALTER preserves the view names used by the report.
*/
USE AdventureWorks2025;
GO

-- One row per customer with an order. StoreID takes precedence over PersonID:
-- a store account may also have a person contact.
CREATE OR ALTER VIEW analytics.vw_DimCustomer
AS
SELECT DISTINCT
    c.CustomerID,
    c.AccountNumber,
    CASE
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unknown'
    END AS CustomerType,
    CASE
        WHEN c.StoreID IS NOT NULL THEN s.Name
        WHEN c.PersonID IS NOT NULL THEN
            CONCAT(
                p.FirstName,
                CASE
                    WHEN p.MiddleName IS NOT NULL
                    THEN ' ' + p.MiddleName
                    ELSE ''
                END,
                ' ',
                p.LastName
            )
        ELSE 'Unknown Customer'
    END AS CustomerName,
    c.TerritoryID,
    COALESCE(t.Name, 'Unassigned') AS TerritoryName,
    COALESCE(t.CountryRegionCode, 'N/A') AS CountryRegionCode,
    COALESCE(t.[Group], 'Unassigned') AS TerritoryGroup
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.Customer AS c
    ON h.CustomerID = c.CustomerID
LEFT JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID
LEFT JOIN Sales.Store AS s
    ON c.StoreID = s.BusinessEntityID
LEFT JOIN Sales.SalesTerritory AS t
    ON c.TerritoryID = t.TerritoryID;
GO

-- One row per sold product. Unsold catalog items are intentionally excluded.
-- Missing color and size receive display labels.
CREATE OR ALTER VIEW analytics.vw_DimProduct
AS
SELECT DISTINCT
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    COALESCE(p.Color, 'Not Specified') AS Color,
    p.StandardCost,
    p.ListPrice,
    COALESCE(p.Size, 'Not Specified') AS Size,
    ps.Name AS ProductSubcategory,
    pc.Name AS ProductCategory
FROM Sales.SalesOrderDetail AS d
INNER JOIN Production.Product AS p
    ON d.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID;
GO

-- One row per territory, joined using the transaction TerritoryID rather than
-- the customer's current-territory attribute.
CREATE OR ALTER VIEW analytics.vw_DimTerritory
AS
SELECT
    TerritoryID,
    Name AS TerritoryName,
    CountryRegionCode,
    [Group] AS TerritoryGroup
FROM Sales.SalesTerritory;
GO

-- One row per salesperson plus key -1 for orders with no assigned salesperson.
-- This label is not a channel definition: use FactSales.SalesChannel.
CREATE OR ALTER VIEW analytics.vw_DimSalesPerson
AS
SELECT
    -1 AS SalesPersonID,
    'Online / No Salesperson' AS SalesPersonName,
    CAST(NULL AS MONEY) AS SalesQuota,
    CAST(0 AS MONEY) AS Bonus,
    CAST(0 AS SMALLMONEY) AS CommissionPct
UNION ALL
SELECT
    sp.BusinessEntityID AS SalesPersonID,
    CONCAT(
        p.FirstName,
        CASE
            WHEN p.MiddleName IS NOT NULL
            THEN ' ' + p.MiddleName
            ELSE ''
        END,
        ' ',
        p.LastName
    ) AS SalesPersonName,
    sp.SalesQuota,
    sp.Bonus,
    sp.CommissionPct
FROM Sales.SalesPerson AS sp
LEFT JOIN Person.Person AS p
    ON sp.BusinessEntityID = p.BusinessEntityID;
GO

-- Date dimension exposed through the same analytics view interface as the other dimensions.
CREATE OR ALTER VIEW analytics.vw_DimDate
AS
SELECT
    DateKey,
    FullDate,
    CalendarYear,
    QuarterNumber,
    QuarterName,
    MonthNumber,
    MonthName,
    MonthShortName,
    YearMonth,
    DayOfMonth,
    DayName,
    DayOfWeek
FROM analytics.DimDate;
GO
