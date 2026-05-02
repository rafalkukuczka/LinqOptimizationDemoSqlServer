/*
    LINQ Optimization Demo - SQL Server setup script

    Creates database, tables, indexes and demo data.
    Default data volume:
      - 20,000 customers
      - 100,000 orders

    Run in SQL Server Management Studio or with sqlcmd:
      sqlcmd -S "(localdb)\MSSQLLocalDB" -i scripts\create-and-seed.sql
*/

IF DB_ID(N'LinqOptimizationDemo') IS NULL
BEGIN
    CREATE DATABASE LinqOptimizationDemo;
END
GO

ALTER DATABASE LinqOptimizationDemo SET QUERY_STORE = ON;
GO

USE LinqOptimizationDemo;
GO

IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL
    DROP TABLE dbo.Orders;
GO

IF OBJECT_ID(N'dbo.Customers', N'U') IS NOT NULL
    DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers
(
    Id              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
    Name            NVARCHAR(200) NOT NULL,
    Email           NVARCHAR(300) NOT NULL,
    NormalizedEmail NVARCHAR(300) NOT NULL,
    City            NVARCHAR(100) NOT NULL,
    IsActive        BIT NOT NULL,
    CreatedAt       DATETIME2(0) NOT NULL
);
GO

CREATE TABLE dbo.Orders
(
    Id          INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
    CustomerId  INT NOT NULL,
    OrderNumber NVARCHAR(50) NOT NULL,
    CreatedAt   DATETIME2(0) NOT NULL,
    Total       DECIMAL(18,2) NOT NULL,
    Status      NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(Id)
);
GO

CREATE INDEX IX_Customers_IsActive ON dbo.Customers(IsActive);
CREATE INDEX IX_Customers_City ON dbo.Customers(City);
CREATE INDEX IX_Customers_Name ON dbo.Customers(Name);
CREATE UNIQUE INDEX IX_Customers_NormalizedEmail ON dbo.Customers(NormalizedEmail);
CREATE INDEX IX_Customers_CreatedAt ON dbo.Customers(CreatedAt);

CREATE INDEX IX_Orders_CustomerId ON dbo.Orders(CustomerId);
CREATE INDEX IX_Orders_CreatedAt ON dbo.Orders(CreatedAt);
CREATE INDEX IX_Orders_Status ON dbo.Orders(Status);
CREATE INDEX IX_Orders_Status_CustomerId_Total ON dbo.Orders(Status, CustomerId) INCLUDE (Total);
GO

SET NOCOUNT ON;

;WITH N AS
(
    SELECT TOP (20000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Customers
(
    Name,
    Email,
    NormalizedEmail,
    City,
    IsActive,
    CreatedAt
)
SELECT
    CASE WHEN n % 10 = 0 THEN CONCAT(N'John Customer ', n) ELSE CONCAT(N'Customer ', n) END,
    CONCAT(N'customer', n, N'@',
        CASE n % 4
            WHEN 0 THEN N'example.com'
            WHEN 1 THEN N'factory.test'
            WHEN 2 THEN N'pkey.info'
            ELSE N'demo.local'
        END),
    UPPER(CONCAT(N'customer', n, N'@',
        CASE n % 4
            WHEN 0 THEN N'example.com'
            WHEN 1 THEN N'factory.test'
            WHEN 2 THEN N'pkey.info'
            ELSE N'demo.local'
        END)),
    CASE n % 8
        WHEN 0 THEN N'Warsaw'
        WHEN 1 THEN N'Berlin'
        WHEN 2 THEN N'Munich'
        WHEN 3 THEN N'Zurich'
        WHEN 4 THEN N'Vienna'
        WHEN 5 THEN N'Gdansk'
        WHEN 6 THEN N'Poznan'
        ELSE N'Hamburg'
    END,
    CASE WHEN n % 3 <> 0 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END,
    DATEADD(day, n % 1500, CONVERT(datetime2(0), '2020-01-01'))
FROM N;
GO

;WITH CustomerNumbers AS
(
    SELECT Id
    FROM dbo.Customers
),
OrderNumbers AS
(
    SELECT v.OrderNo
    FROM (VALUES (1),(2),(3),(4),(5)) v(OrderNo)
)
INSERT INTO dbo.Orders
(
    CustomerId,
    OrderNumber,
    CreatedAt,
    Total,
    Status
)
SELECT
    c.Id,
    CONCAT(N'ORD-', RIGHT(CONCAT(N'000000', c.Id), 6), N'-', RIGHT(CONCAT(N'00', o.OrderNo), 2)),
    DATEADD(day, (ABS(CHECKSUM(c.Id * 1000 + o.OrderNo)) % 1500), CONVERT(datetime2(0), '2020-01-01')),
    CAST(((ABS(CHECKSUM(c.Id * 7919 + o.OrderNo * 104729)) % 500000) / 100.0 + 50.00) AS DECIMAL(18,2)),
    CASE
        WHEN o.OrderNo % 4 = 0 THEN N'Cancelled'
        WHEN o.OrderNo % 3 = 0 THEN N'Pending'
        ELSE N'Completed'
    END
FROM CustomerNumbers c
CROSS JOIN OrderNumbers o;
GO

UPDATE STATISTICS dbo.Customers WITH FULLSCAN;
UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
GO

SELECT COUNT(*) AS CustomersCount FROM dbo.Customers;
SELECT COUNT(*) AS OrdersCount FROM dbo.Orders;
GO
