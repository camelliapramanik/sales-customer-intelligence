/*
05_Data_Validation.sql
Purpose: validate the completed analytics layer before a Power BI refresh.
Prerequisite: run scripts 02, 03, and 04 in order.
Read-only: no source or analytics objects are modified.
Result 1: structural checks (all must PASS; THROW stops a failed sqlcmd run).
Result 2: observed totals for comparison with docs/metadata/snapshot.json.
Result 3: revenue reconciliation using the SAME per-line rounding as the fact.
Result 4: historical-cost coverage diagnostics, requiring review, not auto-failure.
*/
USE AdventureWorks2025;
GO
SET NOCOUNT ON;

DECLARE @Checks TABLE
(
    CheckName VARCHAR(100) NOT NULL,
    Failures BIGINT NOT NULL
);

INSERT INTO @Checks
SELECT 'Fact has rows', CASE WHEN EXISTS (SELECT 1 FROM analytics.vw_FactSales) THEN 0 ELSE 1 END
UNION ALL
SELECT 'Fact row count equals source detail count',
    ABS((SELECT COUNT_BIG(*) FROM analytics.vw_FactSales)
      - (SELECT COUNT_BIG(*) FROM Sales.SalesOrderDetail))
UNION ALL
SELECT 'Unique sales detail keys', COUNT_BIG(*)
FROM (SELECT SalesOrderDetailID FROM analytics.vw_FactSales GROUP BY SalesOrderDetailID HAVING COUNT(*) > 1) AS x
UNION ALL
SELECT 'Unique customer keys', COUNT_BIG(*)
FROM (SELECT CustomerID FROM analytics.vw_DimCustomer GROUP BY CustomerID HAVING COUNT(*) > 1) AS x
UNION ALL
SELECT 'Unique product keys', COUNT_BIG(*)
FROM (SELECT ProductID FROM analytics.vw_DimProduct GROUP BY ProductID HAVING COUNT(*) > 1) AS x
UNION ALL
SELECT 'Unique salesperson keys', COUNT_BIG(*)
FROM (SELECT SalesPersonID FROM analytics.vw_DimSalesPerson GROUP BY SalesPersonID HAVING COUNT(*) > 1) AS x
UNION ALL
SELECT 'Unique territory keys', COUNT_BIG(*)
FROM (SELECT TerritoryID FROM analytics.vw_DimTerritory GROUP BY TerritoryID HAVING COUNT(*) > 1) AS x
UNION ALL
SELECT 'Unique calendar dates', COUNT_BIG(*)
FROM (SELECT FullDate FROM analytics.vw_DimDate GROUP BY FullDate HAVING COUNT(*) > 1) AS x;

INSERT INTO @Checks
SELECT 'Unmatched customers', COUNT_BIG(*)
FROM analytics.vw_FactSales AS f
WHERE NOT EXISTS (SELECT 1 FROM analytics.vw_DimCustomer AS d WHERE d.CustomerID = f.CustomerID)
UNION ALL
SELECT 'Unmatched products', COUNT_BIG(*)
FROM analytics.vw_FactSales AS f
WHERE NOT EXISTS (SELECT 1 FROM analytics.vw_DimProduct AS d WHERE d.ProductID = f.ProductID)
UNION ALL
SELECT 'Unmatched salespeople', COUNT_BIG(*)
FROM analytics.vw_FactSales AS f
WHERE NOT EXISTS (SELECT 1 FROM analytics.vw_DimSalesPerson AS d WHERE d.SalesPersonID = f.SalesPersonID)
UNION ALL
SELECT 'Unmatched territories', COUNT_BIG(*)
FROM analytics.vw_FactSales AS f
WHERE NOT EXISTS (SELECT 1 FROM analytics.vw_DimTerritory AS d WHERE d.TerritoryID = f.TerritoryID)
UNION ALL
SELECT 'Unmatched order dates', COUNT_BIG(*)
FROM analytics.vw_FactSales AS f
WHERE NOT EXISTS (SELECT 1 FROM analytics.vw_DimDate AS d WHERE d.DateKey = f.OrderDateKey)
UNION ALL
SELECT 'Continuous date range',
    CASE
        WHEN COUNT_BIG(*) = 0 THEN 1
        ELSE ABS(COUNT_BIG(*) - (DATEDIFF(DAY, MIN(FullDate), MAX(FullDate)) + 1))
    END
FROM analytics.vw_DimDate
UNION ALL
SELECT 'Date keys match full dates', COUNT_BIG(*)
FROM analytics.vw_DimDate
WHERE DateKey <> CONVERT(INT, CONVERT(CHAR(8), FullDate, 112))
UNION ALL
SELECT 'Profit reconciles within one cent per line', COUNT_BIG(*)
FROM analytics.vw_FactSales
WHERE ABS(SalesAmount - TotalProductCost - Profit) > 0.01;

SELECT CheckName, Failures, CASE WHEN Failures = 0 THEN 'PASS' ELSE 'FAIL' END AS Result
FROM @Checks
ORDER BY CheckName;

IF EXISTS (SELECT 1 FROM @Checks WHERE Failures <> 0)
BEGIN
    THROW 50002, 'Analytics validation failed. Review the FAIL result sets before refresh.', 1;
END;

SELECT
    COUNT_BIG(*) AS FactRows,
    COUNT(DISTINCT SalesOrderID) AS Orders,
    COUNT(DISTINCT CustomerID) AS Customers,
    COUNT(DISTINCT ProductID) AS Products,
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate,
    SUM(CAST(OrderQty AS BIGINT)) AS QuantitySold,
    SUM(SalesAmount) AS TotalSales,
    SUM(TotalProductCost) AS TotalCost,
    SUM(Profit) AS TotalProfit,
    SUM(Profit) / NULLIF(SUM(SalesAmount), 0) AS ProfitMargin
FROM analytics.vw_FactSales;

SELECT
    source.TotalSales AS SourceRoundedLineSales,
    fact.TotalSales AS FactSales,
    source.TotalSales - fact.TotalSales AS Difference
FROM (SELECT SUM(CAST(LineTotal AS DECIMAL(18, 2))) AS TotalSales FROM Sales.SalesOrderDetail) AS source
CROSS JOIN (SELECT SUM(SalesAmount) AS TotalSales FROM analytics.vw_FactSales) AS fact;

-- An expired latest-start-date cost is retained by the report's original logic.
-- Do not silently add an EndDate condition: that changes the profit methodology.
SELECT
    SUM(CASE WHEN cost.StandardCost IS NULL THEN 1 ELSE 0 END) AS LinesUsingCurrentCostFallback,
    SUM(CASE WHEN cost.EndDate < h.OrderDate THEN 1 ELSE 0 END) AS LinesAfterSelectedCostEndDate
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
    ON h.SalesOrderID = d.SalesOrderID
OUTER APPLY
(
    SELECT TOP (1) pch.StandardCost, pch.EndDate
    FROM Production.ProductCostHistory AS pch
    WHERE pch.ProductID = d.ProductID
      AND pch.StartDate <= h.OrderDate
    ORDER BY pch.StartDate DESC
) AS cost;
GO
