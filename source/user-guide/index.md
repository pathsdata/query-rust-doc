# User Guide

Comprehensive guides for using PATHSDATA effectively.

## Guides

### [Catalog Configuration](catalogs/index.md)

Detailed configuration for each catalog type:

- AWS Glue - Required/optional options, IAM setup, cross-account
- AWS S3 Tables - ARN format, permissions
- REST - Bearer token, OAuth2, Nessie, Polaris
- SQL - PostgreSQL, MySQL, SQLite connection strings
- File - Local and S3-backed file catalogs
- LanceDB - Vector database configuration

### [Apache Iceberg](iceberg/index.md)

Complete guide to working with Apache Iceberg tables:

- Supported catalogs (Glue, S3 Tables, REST, SQL, File)
- DDL operations (CREATE, DROP, ALTER TABLE)
- DML operations (INSERT, UPDATE, DELETE, MERGE)
- Time travel and snapshots
- Branching and tagging
- Table maintenance (VACUUM, OPTIMIZE)

### [Python API](python/index.md)

Python bindings reference:

- SessionContext initialization
- DataFrame operations
- Catalog and schema access
- Query execution
- Integration with Pandas, Polars, PyArrow

### [SQL Reference](sql/index.md)

Complete SQL syntax documentation:

- Data types
- Functions (aggregate, window, string, date/time)
- Operators and expressions
- Joins and subqueries

### [Iceberg SQL Reference](sql/iceberg-sql.md)

Detailed Iceberg SQL with required/optional clauses:

- CREATE EXTERNAL TABLE - partitioning, options, location
- INSERT, UPDATE, DELETE, MERGE INTO
- Time travel queries
- VACUUM, EXPIRE SNAPSHOTS, OPTIMIZE
- Branching and tagging

### [Configuration](configuration/index.md)

Configuration options:

- AWS credentials and profiles
- S3 connection settings
- Catalog-specific configuration
- Query execution tuning
- Environment variables

## Quick Links

| Task | Guide |
|------|-------|
| Connect to AWS Glue | [Iceberg → Registering Catalogs](iceberg/index.md#registering-catalogs) |
| Run a SQL query | [Python API → Query Execution](python/index.md#query-execution) |
| Use AWS profiles | [Configuration → AWS](configuration/index.md#aws-configuration) |
| Insert data | [SQL Reference → INSERT](sql/index.md#insert) |
| Time travel query | [Iceberg → Time Travel](iceberg/index.md#time-travel) |
| Merge tables | [SQL Reference → MERGE INTO](sql/index.md#merge-into) |
