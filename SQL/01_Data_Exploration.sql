/*
01_Data_Exploration.sql
Purpose: profile the AdventureWorks OLTP source before building the BI layer.
Prerequisite: restore AdventureWorks2025; no analytics objects are required.
Read-only: each result set answers a data-modeling or quality question.
Run order: optional exploration, followed by scripts 02 through 05.
*/
USE AdventureWorks2025;
GO
SET NOCOUNT ON;

-- 1. What period and order population does the source contain?
SELECT
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate,
    COUNT_BIG(*) AS Orders,
    COUNT(DISTINCT CustomerID) AS PurchasingCustomers
FROM Sales.SalesOrderHeader;

-- 2. Inspect the line-item grain. Header subtotal must not be summed after
--    joining to detail because it would repeat once for every order line.
SELECT TOP (20)
    h.SalesOrderID,
    d.SalesOrderDetailID,
    h.OrderDate,
    h.CustomerID,
    h.SalesPersonID,
    h.TerritoryID,
    d.ProductID,
    d.OrderQty,
    d.UnitPrice,
    d.UnitPriceDiscount,
    d.LineTotal AS SalesAmount
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
    ON h.SalesOrderID = d.SalesOrderID
ORDER BY h.SalesOrderID, d.SalesOrderDetailID;

-- 3. Compare the full catalog with products actually sold.
SELECT COUNT(*) AS CatalogProducts FROM Production.Product;
SELECT COUNT(DISTINCT ProductID) AS ProductsSold FROM Sales.SalesOrderDetail;

SELECT
    pc.Name AS ProductCategory,
    COUNT(DISTINCT p.ProductID) AS ProductsSold
FROM Sales.SalesOrderDetail AS d
INNER JOIN Production.Product AS p
    ON d.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory AS ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory AS pc
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY ProductsSold DESC, ProductCategory;

-- 4. Sold products without a category require interpretation in the report.
SELECT DISTINCT
    p.ProductID,
    p.Name AS ProductName
FROM Sales.SalesOrderDetail AS d
INNER JOIN Production.Product AS p
    ON d.ProductID = p.ProductID
WHERE p.ProductSubcategoryID IS NULL
ORDER BY p.ProductID;

-- 5. A store customer may also have a person contact. StoreID must be tested
--    first; testing PersonID first can misclassify reseller accounts.
SELECT
    CASE
        WHEN StoreID IS NOT NULL THEN 'Store'
        WHEN PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unknown'
    END AS CustomerType,
    COUNT(*) AS CustomerAccounts,
    SUM(CASE WHEN StoreID IS NOT NULL AND PersonID IS NOT NULL THEN 1 ELSE 0 END)
        AS AccountsWithStoreAndPerson
FROM Sales.Customer
GROUP BY
    CASE
        WHEN StoreID IS NOT NULL THEN 'Store'
        WHEN PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unknown'
    END;

-- 6. Compare customer type, explicit channel flag, and salesperson assignment.
--    Channel is defined by OnlineOrderFlag, not by the presence of a salesperson.
SELECT
    CASE
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unknown'
    END AS CustomerType,
    CASE WHEN h.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Reseller' END AS SalesChannel,
    CASE WHEN h.SalesPersonID IS NULL THEN 'Unassigned' ELSE 'Assigned' END AS SalesAssignment,
    COUNT(*) AS Orders,
    SUM(h.SubTotal) AS SalesBeforeTaxAndFreight
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.Customer AS c
    ON h.CustomerID = c.CustomerID
GROUP BY
    CASE
        WHEN c.StoreID IS NOT NULL THEN 'Store'
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unknown'
    END,
    CASE WHEN h.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Reseller' END,
    CASE WHEN h.SalesPersonID IS NULL THEN 'Unassigned' ELSE 'Assigned' END
ORDER BY CustomerType, SalesChannel, SalesAssignment;

-- 7. Inspect territory coverage and source attributes.
SELECT
    TerritoryID,
    Name AS TerritoryName,
    CountryRegionCode,
    [Group] AS TerritoryGroup
FROM Sales.SalesTerritory
ORDER BY TerritoryID;

-- 8. Compare current product cost with the as-of cost used by the final fact.
--    This diagnostic explains why today's product cost is not applied to every
--    historical transaction. EndDate is shown for validity-gap review.
SELECT TOP (50)
    h.OrderDate,
    p.ProductID,
    p.Name AS ProductName,
    d.OrderQty,
    p.StandardCost AS CurrentStandardCost,
    cost.StandardCost AS HistoricalStandardCost,
    cost.StartDate AS CostStartDate,
    cost.EndDate AS CostEndDate,
    CASE WHEN cost.StandardCost IS NULL THEN 1 ELSE 0 END AS UsesCurrentCostFallback
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
    ON h.SalesOrderID = d.SalesOrderID
INNER JOIN Production.Product AS p
    ON d.ProductID = p.ProductID
OUTER APPLY
(
    SELECT TOP (1)
        pch.StandardCost,
        pch.StartDate,
        pch.EndDate
    FROM Production.ProductCostHistory AS pch
    WHERE pch.ProductID = d.ProductID
      AND pch.StartDate <= h.OrderDate
    ORDER BY pch.StartDate DESC
) AS cost
WHERE p.Name = 'Road-250 Black, 44'
ORDER BY h.OrderDate, d.SalesOrderDetailID;
GO
