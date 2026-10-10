/*
02_Analytics_Schema_and_Date.sql
Purpose: create the analytics schema and a continuous order-date dimension.
Prerequisite: restore the AdventureWorks2025 OLTP sample database.
Rerun behavior: creates the table only when absent and inserts missing dates.
Existing rows are preserved; no source tables or analytics objects are dropped.
The date range matches the original report: first through last order date.
English labels and Sunday = 1 are explicit to avoid session-locale differences.
*/
USE AdventureWorks2025;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET LANGUAGE us_english;
SET DATEFIRST 7;

IF SCHEMA_ID(N'analytics') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA analytics');
END;
GO

IF OBJECT_ID(N'analytics.DimDate', N'U') IS NULL
BEGIN
    CREATE TABLE analytics.DimDate
    (
        DateKey        INT NOT NULL PRIMARY KEY,
        FullDate       DATE NOT NULL,
        CalendarYear   INT NOT NULL,
        QuarterNumber  INT NOT NULL,
        QuarterName    VARCHAR(2) NOT NULL,
        MonthNumber    INT NOT NULL,
        MonthName      VARCHAR(20) NOT NULL,
        MonthShortName VARCHAR(3) NOT NULL,
        YearMonth      CHAR(7) NOT NULL,
        DayOfMonth     INT NOT NULL,
        DayName        VARCHAR(20) NOT NULL,
        DayOfWeek      INT NOT NULL
    );
END;
GO

DECLARE @StartDate DATE;
DECLARE @EndDate DATE;

SELECT
    @StartDate = CAST(MIN(OrderDate) AS DATE),
    @EndDate = CAST(MAX(OrderDate) AS DATE)
FROM Sales.SalesOrderHeader;

IF @StartDate IS NULL OR @EndDate IS NULL
BEGIN
    THROW 50001, 'SalesOrderHeader contains no dates. Restore the OLTP sample first.', 1;
END;

-- Recursive enumeration avoids relying on the size of system catalog tables.
;WITH Dates AS
(
    SELECT @StartDate AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM Dates
    WHERE FullDate < @EndDate
)
INSERT INTO analytics.DimDate
(
    DateKey, FullDate, CalendarYear, QuarterNumber, QuarterName,
    MonthNumber, MonthName, MonthShortName, YearMonth,
    DayOfMonth, DayName, DayOfWeek
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), d.FullDate, 112)),
    d.FullDate,
    YEAR(d.FullDate),
    DATEPART(QUARTER, d.FullDate),
    CONCAT('Q', DATEPART(QUARTER, d.FullDate)),
    MONTH(d.FullDate),
    DATENAME(MONTH, d.FullDate),
    LEFT(DATENAME(MONTH, d.FullDate), 3),
    CONVERT(CHAR(7), d.FullDate, 126),
    DAY(d.FullDate),
    DATENAME(WEEKDAY, d.FullDate),
    DATEPART(WEEKDAY, d.FullDate)
FROM Dates AS d
WHERE NOT EXISTS
(
    SELECT 1
    FROM analytics.DimDate AS existing
    WHERE existing.DateKey = CONVERT(INT, CONVERT(CHAR(8), d.FullDate, 112))
)
OPTION (MAXRECURSION 0);

SELECT
    COUNT(*) AS NumberOfDates,
    MIN(FullDate) AS FirstDate,
    MAX(FullDate) AS LastDate
FROM analytics.DimDate;
GO
