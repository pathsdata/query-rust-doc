# Python API Reference

PATHSDATA provides comprehensive Python bindings via PyO3, offering a Pythonic interface to the high-performance Rust query engine.

## Installation

```bash
pip install pathsdata-test
```

## Core Classes

### SessionContext

The main entry point for all operations. Manages catalogs, executes queries, and handles configuration.

```python
from pathsdata_test import SessionContext

# Basic initialization
ctx = SessionContext()

# With AWS configuration
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"
})

# With explicit credentials
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.access_key_id": "AKIA...",
    "aws.secret_access_key": "..."
})
```

#### Methods

| Method | Description |
|--------|-------------|
| `sql(query)` | Execute a SQL query, returns DataFrame |
| `read_parquet(path)` | Read Parquet file(s) |
| `read_csv(path)` | Read CSV file(s) |
| `read_json(path)` | Read JSON file(s) |
| `register_iceberg(name, config)` | Register an Iceberg catalog |
| `register_lancedb(name, config)` | Register a LanceDB catalog |
| `register_parquet(name, path)` | Register Parquet as a table |
| `register_csv(name, path)` | Register CSV as a table |
| `catalog(name)` | Get a catalog by name |
| `table(name)` | Get a table by name |

### DataFrame

Represents a lazy query plan. Operations are not executed until you call `collect()` or `show()`.

```python
# Create DataFrame from SQL
df = ctx.sql("SELECT * FROM my_table")

# Chain operations
result = df.filter("age > 21").select("name", "age").limit(10)

# Execute and collect results
batches = result.collect()

# Display results
result.show()
result.show(20)  # Show 20 rows
```

#### Methods

| Method | Description |
|--------|-------------|
| `select(*columns)` | Select specific columns |
| `filter(predicate)` | Filter rows by condition |
| `limit(n)` | Limit to n rows |
| `sort(*columns)` | Sort by columns |
| `distinct()` | Remove duplicate rows |
| `collect()` | Execute and return RecordBatches |
| `show(n=10)` | Display n rows to console |
| `to_pandas()` | Convert to Pandas DataFrame |
| `to_polars()` | Convert to Polars DataFrame |
| `to_arrow()` | Convert to PyArrow Table |

### RecordBatch

Arrow RecordBatch containing query results.

```python
batches = df.collect()
for batch in batches:
    # Convert to Pandas
    pandas_df = batch.to_pandas()
    print(pandas_df)

    # Access schema
    print(batch.schema)

    # Access columns
    print(batch.column(0))
```

## Catalog Operations

### Registering Catalogs

#### Iceberg Catalogs

```python
# AWS Glue
ctx.register_iceberg("warehouse", {
    "type": "glue",
    "glue.region": "us-east-1"
})

# AWS S3 Tables
ctx.register_iceberg("s3tables", {
    "type": "s3tables",
    "s3tables.table-bucket-arn": "arn:aws:s3tables:us-east-1:123456789012:bucket/my-bucket",
    "s3tables.region": "us-east-1"
})

# REST Catalog
ctx.register_iceberg("rest", {
    "type": "rest",
    "uri": "https://catalog.example.com",
    "rest.token": "bearer-token"
})

# SQL Catalog
ctx.register_iceberg("sql", {
    "type": "sql",
    "uri": "postgresql://user:pass@localhost/iceberg"
})

# File Catalog (local testing)
ctx.register_iceberg("local", {
    "type": "file",
    "warehouse": "/path/to/warehouse"
})
```

#### LanceDB Catalogs

```python
# Local LanceDB
ctx.register_lancedb("vectors", {
    "uri": "/path/to/lancedb"
})

# S3-backed LanceDB
ctx.register_lancedb("vectors", {
    "uri": "s3://my-bucket/lancedb/"
})
```

### Accessing Catalogs

```python
# Get catalog
catalog = ctx.catalog("warehouse")

# List schemas/databases
schemas = catalog.schema_names()
print(f"Schemas: {schemas}")

# Get specific schema
schema = catalog.schema("analytics")

# List tables in schema
tables = schema.table_names()
print(f"Tables: {tables}")
```

## Query Execution

### SQL Queries

```python
# Simple query
df = ctx.sql("SELECT * FROM warehouse.db.users LIMIT 10")

# With parameters (when supported)
df = ctx.sql("""
    SELECT * FROM warehouse.db.events
    WHERE event_date > '2024-01-01'
    AND user_id = 123
""")

# Collect results
batches = df.collect()
for batch in batches:
    print(batch.to_pandas())
```

### DML Operations

```python
# INSERT
ctx.sql("""
    INSERT INTO warehouse.db.users (id, name, email)
    VALUES (1, 'Alice', 'alice@example.com')
""").collect()

# UPDATE
ctx.sql("""
    UPDATE warehouse.db.users
    SET status = 'active'
    WHERE last_login > '2024-01-01'
""").collect()

# DELETE
ctx.sql("""
    DELETE FROM warehouse.db.users
    WHERE status = 'inactive'
""").collect()

# MERGE INTO
ctx.sql("""
    MERGE INTO warehouse.db.users AS target
    USING staging.updates AS source
    ON target.id = source.id
    WHEN MATCHED THEN UPDATE SET
        name = source.name,
        email = source.email
    WHEN NOT MATCHED THEN INSERT
        (id, name, email)
        VALUES (source.id, source.name, source.email)
""").collect()
```

### Time Travel

```python
# Query at specific snapshot
df = ctx.sql("""
    SELECT * FROM warehouse.db.users
    VERSION AS OF 1234567890
""")

# Query at timestamp
df = ctx.sql("""
    SELECT * FROM warehouse.db.users
    TIMESTAMP AS OF '2024-01-15 10:00:00'
""")
```

## Reading Files

### Parquet

```python
# Single file
df = ctx.read_parquet("data.parquet")

# Multiple files with glob
df = ctx.read_parquet("data/*.parquet")

# From S3
df = ctx.read_parquet("s3://bucket/path/data.parquet")

# With SQL
df = ctx.sql("SELECT * FROM 'data.parquet'")
df = ctx.sql("SELECT * FROM 's3://bucket/path/*.parquet'")
```

### CSV

```python
# Read CSV
df = ctx.read_csv("data.csv")

# With options
df = ctx.read_csv("data.csv", has_header=True, delimiter=",")

# Register as table
ctx.register_csv("my_table", "data.csv")
df = ctx.sql("SELECT * FROM my_table")
```

### JSON

```python
# Read JSON (newline-delimited)
df = ctx.read_json("data.json")

# From S3
df = ctx.read_json("s3://bucket/data.json")
```

## Integration with Data Science Libraries

### Pandas

```python
import pandas as pd

# Query to Pandas
df = ctx.sql("SELECT * FROM warehouse.db.users")
pandas_df = df.to_pandas()

# Or from batches
batches = df.collect()
pandas_dfs = [batch.to_pandas() for batch in batches]
combined = pd.concat(pandas_dfs)
```

### Polars

```python
import polars as pl

# Query to Polars
df = ctx.sql("SELECT * FROM warehouse.db.users")
polars_df = df.to_polars()

# Use Polars operations
result = polars_df.filter(pl.col("age") > 21).select(["name", "age"])
```

### PyArrow

```python
import pyarrow as pa

# Query to Arrow Table
df = ctx.sql("SELECT * FROM warehouse.db.users")
arrow_table = df.to_arrow()

# Write to Parquet
import pyarrow.parquet as pq
pq.write_table(arrow_table, "output.parquet")
```

## Error Handling

```python
from pathsdata_test import SessionContext

ctx = SessionContext({"aws.region": "us-east-1"})

try:
    ctx.register_iceberg("warehouse", {"type": "glue"})
except Exception as e:
    print(f"Failed to register catalog: {e}")

try:
    df = ctx.sql("SELECT * FROM nonexistent_table")
    df.collect()
except Exception as e:
    print(f"Query failed: {e}")
```

## Configuration Options

### AWS Configuration

| Option | Description |
|--------|-------------|
| `aws.region` | AWS region (e.g., "us-east-1") |
| `aws.profile_name` | AWS profile from ~/.aws/credentials |
| `aws.access_key_id` | Explicit access key |
| `aws.secret_access_key` | Explicit secret key |
| `aws.session_token` | Session token (for temporary credentials) |
| `aws.endpoint` | Custom endpoint (for LocalStack, MinIO) |
| `aws.role_arn` | IAM role ARN for role assumption |

### S3 Configuration

| Option | Description |
|--------|-------------|
| `s3.region` | S3-specific region override |
| `s3.endpoint` | S3 endpoint URL |
| `s3.max_connections` | Connection pool size (default: 16) |
| `s3.connect_timeout` | Connection timeout in seconds |
| `s3.read_timeout` | Read timeout in seconds |

### Iceberg Streaming Configuration

Control read/write parallelism for Iceberg tables:

| Option | Default | Description |
|--------|---------|-------------|
| `iceberg.max_concurrent_files` | 4 | Max data files to read in parallel |
| `iceberg.max_concurrent_partitions` | 8 | Max partitions to write in parallel |
| `iceberg.max_concurrent_writers` | 10 | Max concurrent write operations |
| `iceberg.buffer_size` | 2 | Record batches buffered per stream |
| `iceberg.parallel_manifest_reads` | true | Enable parallel manifest reading |

```python
# Configure via SessionContext
ctx = SessionContext({
    "aws.region": "us-east-1",
    "iceberg.max_concurrent_files": 16,
    "iceberg.max_concurrent_writers": 10
})

# Or via SQL SET commands
ctx.sql("SET iceberg.max_concurrent_files = 16")
ctx.sql("SET iceberg.max_concurrent_writers = 10")
```

**Performance tip:** For maximum write throughput, use fewer concurrent writers (1-5) due to Iceberg commit contention. For reads, higher `max_concurrent_files` (8-16) provides significant speedup.

## Complete Example

```python
from pathsdata_test import SessionContext

# Initialize with AWS config
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "data-team"
})

# Register Iceberg catalog
ctx.register_iceberg("warehouse", {
    "type": "glue",
    "glue.region": "us-east-1"
})

# List available databases
catalog = ctx.catalog("warehouse")
print(f"Databases: {catalog.schema_names()}")

# Query data
df = ctx.sql("""
    SELECT
        user_id,
        COUNT(*) as event_count,
        MAX(event_time) as last_event
    FROM warehouse.analytics.events
    WHERE event_date >= '2024-01-01'
    GROUP BY user_id
    ORDER BY event_count DESC
    LIMIT 100
""")

# Convert to Pandas for analysis
pandas_df = df.to_pandas()
print(pandas_df.describe())

# Write results to new Iceberg table
ctx.sql("""
    INSERT INTO warehouse.analytics.user_summary
    SELECT user_id, event_count, last_event
    FROM staging_results
""").collect()

print("Analysis complete!")
```

## Next Steps

- [SQL Reference](../sql/index.md) - Complete SQL syntax
- [Configuration](../configuration/index.md) - All configuration options
- [Iceberg Guide](../iceberg/index.md) - Iceberg-specific features
