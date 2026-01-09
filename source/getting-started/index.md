# Getting Started

PathsData is a high-performance query engine built on Apache DataFusion with native support for Apache Iceberg and LanceDB. It provides both Python and Rust APIs for querying data lakes with full ACID transaction support.

## Quick Start

### Python Installation

```bash
pip install pathsdata-test
```

### Basic Usage

```python
from pathsdata_test import SessionContext

# Create a session
ctx = SessionContext()

# Query local files
df = ctx.read_parquet("data.parquet")
df.show(10)

# Or use SQL
result = ctx.sql("SELECT * FROM 'data.parquet' LIMIT 10")
result.show(10)
```

### Connect to Iceberg (AWS Glue)

```python
from pathsdata_test import SessionContext

# Configure AWS credentials
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"  # Uses ~/.aws/credentials
})

# Register Glue catalog
ctx.register_iceberg("warehouse", {
    "type": "glue",
    "glue.region": "us-east-1"
})

# Query Iceberg tables
df = ctx.sql("SELECT * FROM warehouse.my_database.my_table LIMIT 10")
for batch in df.collect():
    print(batch.to_pandas())
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Apache Iceberg** | Full read/write support with ACID transactions |
| **Multiple Catalogs** | Glue, S3 Tables, REST, SQL, File catalogs |
| **DML Operations** | INSERT, UPDATE, DELETE, MERGE INTO |
| **Time Travel** | Query historical snapshots |
| **Partition Pruning** | Automatic optimization |
| **Python & Rust APIs** | Native bindings for both languages |

## Next Steps

- [Iceberg User Guide](../user-guide/iceberg/index.md) - Learn about Iceberg table operations
- [Python API](../user-guide/python/index.md) - Complete Python API reference
- [SQL Reference](../user-guide/sql/index.md) - SQL syntax and supported statements
- [Configuration](../user-guide/configuration/index.md) - AWS and performance tuning options
