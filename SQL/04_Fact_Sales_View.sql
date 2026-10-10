/*
04_Fact_Sales_View.sql
Purpose: expose sales at one row per sales order detail (SalesOrderDetailID).
Prerequisite: run 02_Analytics_Schema_and_Date.sql.
Source: SalesOrderHeader + SalesOrderDetail + Product + ProductCostHistory.

Business rules retained from the final original query:
- OnlineOrderFlag = 1 means Online; all other orders are labelled Reseller.
- Missing SalesPersonID maps to dimension key -1.
- SalesAmount is discounted line revenue, excluding order tax and freight.
- Cost uses the most recent ProductCostHistory.StartDate <= OrderDate.
- If no earlier cost exists, current Product.StandardCost is the fallback.
- EndDate is deliberately not tested, matching the original report logic.
  This is an as-of start-date estimate; gaps in validity should be reviewed.
- Profit is estimated line revenue minus standard product cost, not net income.
- Monetary outputs are rounded per line; aggregate rounding can differ from
  rounding a single unrounded grand total.

Rerun behavior: replaces only the definition of analytics.vw_FactSales.
*/
USE AdventureWorks2025;
GO

CREATE OR ALTER VIEW analytics.vw_FactSales
AS
SELECT
    d.SalesOrderDetailID,
    h.SalesOrderID,
    CONVERT(INT, CONVERT(CHAR(8), h.OrderDate, 112)) AS OrderDateKey,
    CAST(h.OrderDate AS DATE) AS OrderDate,
    CAST(h.DueDate AS DATE) AS DueDate,
    CAST(h.ShipDate AS DATE) AS ShipDate,
    h.CustomerID,
    COALESCE(h.SalesPersonID, -1) AS SalesPersonID,
    h.TerritoryID,
    d.ProductID,
    CASE
        WHEN h.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Reseller'
    END AS SalesChannel,
    d.OrderQty,
    d.UnitPrice,
    d.UnitPriceDiscount,
    CAST(d.UnitPrice * d.OrderQty AS DECIMAL(18, 2)) AS GrossSales,
    CAST(
        (d.UnitPrice * d.OrderQty) - d.LineTotal
        AS DECIMAL(18, 2)
    ) AS DiscountAmount,
    CAST(d.LineTotal AS DECIMAL(18, 2)) AS SalesAmount,
    CAST(
        COALESCE(cost.StandardCost, p.StandardCost)
        AS DECIMAL(18, 4)
    ) AS UnitStandardCost,
    CAST(
        COALESCE(cost.StandardCost, p.StandardCost) * d.OrderQty
        AS DECIMAL(18, 2)
    ) AS TotalProductCost,
    CAST(
        d.LineTotal - (COALESCE(cost.StandardCost, p.StandardCost) * d.OrderQty)
        AS DECIMAL(18, 2)
    ) AS Profit
FROM Sales.SalesOrderHeader AS h
INNER JOIN Sales.SalesOrderDetail AS d
    ON h.SalesOrderID = d.SalesOrderID
INNER JOIN Production.Product AS p
    ON d.ProductID = p.ProductID
OUTER APPLY
(
    SELECT TOP (1)
        pch.StandardCost
    FROM Production.ProductCostHistory AS pch
    WHERE pch.ProductID = d.ProductID
      AND pch.StartDate <= h.OrderDate
    ORDER BY pch.StartDate DESC
) AS cost;
GO
