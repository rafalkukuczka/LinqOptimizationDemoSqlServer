# LINQ Optimization Demo - SQL Server

This project demonstrates LINQ / EF Core performance techniques against SQL Server.

It includes:

- `IQueryable` vs `IEnumerable`
- `ToQueryString()` generated SQL inspection
- EF Core SQL logging
- slow query interceptor
- N+1 query problem
- projection vs full entity loading
- `AsNoTracking()`
- `Any()` vs `Count()`
- pagination: offset vs keyset
- index-friendly date and string filtering
- aggregation in SQL Server
- `Contains()` / SQL `IN` batching
- `GroupBy()` + `Sum()` in SQL Server
- SQL Server Query Store enabled

## Requirements

- .NET 8 SDK
- SQL Server or SQL Server LocalDB
- Visual Studio 2022 or terminal

## 1. Create and seed database

Run the SQL script first.

### Option A - SQL Server Management Studio

Open:

```text
scripts/create-and-seed.sql
```

Execute it.

It creates:

```text
Database: LinqOptimizationDemo
Customers: 20,000
Orders:    100,000
```

### Option B - sqlcmd

```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -i scripts\create-and-seed.sql
```

## 2. Run project

```powershell
dotnet run --project src/LinqOptimizationDemoSqlServer/LinqOptimizationDemoSqlServer.csproj
```

## 3. Custom connection string

By default, the project uses LocalDB:

```text
Server=(localdb)\MSSQLLocalDB;Database=LinqOptimizationDemo;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true
```

You can override it with an environment variable.

### PowerShell

```powershell
$env:LINQ_DEMO_CONNECTION="Server=localhost;Database=LinqOptimizationDemo;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true"
dotnet run --project src/LinqOptimizationDemoSqlServer/LinqOptimizationDemoSqlServer.csproj
```

## 4. Where to look

Important files:

```text
scripts/create-and-seed.sql
src/LinqOptimizationDemoSqlServer/Program.cs
```

The SQL file creates all tables and indexes. The C# project only maps existing tables and runs LINQ examples.

## 5. Useful SQL Server diagnostics

Query Store is enabled by the script:

```sql
ALTER DATABASE LinqOptimizationDemo SET QUERY_STORE = ON;
```

In SSMS, open:

```text
Database -> Query Store -> Top Resource Consuming Queries
```

You can also run:

```sql
USE LinqOptimizationDemo;
GO

SELECT TOP 20
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    qs.execution_count,
    qs.total_elapsed_time,
    st.text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY avg_elapsed_time DESC;
```

## 6. Reset demo database

Just execute `scripts/create-and-seed.sql` again. It drops and recreates the demo tables.

## Notes

This is an educational demo. Some queries are intentionally bad so you can see the difference in logs and timings.

## Suggested article section

You can use this project as a downloadable companion for an article titled:

**How to Optimize LINQ Queries in C#: Complete Performance, Logging & Diagnostics Guide:**
https://pkey.info/knowledge-base/optimize-linq-queries-csharp-performance/
