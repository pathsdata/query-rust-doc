# PathsData Documentation

PathsData is a high-performance query engine built on Apache DataFusion with native support for Apache Iceberg and LanceDB. Query your data lake with full ACID transactions, time travel, and lightning-fast performance.

## Features

- **Apache Iceberg** - Full read/write support with ACID transactions
- **Multiple Catalogs** - AWS Glue, S3 Tables, REST, SQL, File
- **DML Operations** - INSERT, UPDATE, DELETE, MERGE INTO
- **Time Travel** - Query historical data snapshots
- **LanceDB Integration** - Vector database support
- **Python & Rust APIs** - Native bindings for both languages
- **High Performance** - Built on Apache Arrow and DataFusion

## Quick Start

```python
from pathsdata_test import SessionContext

# Create a session with AWS config
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"
})

# Register Iceberg catalog (AWS Glue)
ctx.register_iceberg("warehouse", {
    "type": "glue"
})

# Query your data lake
df = ctx.sql("""
    SELECT * FROM warehouse.analytics.events
    WHERE event_date >= '2024-01-01'
    LIMIT 100
""")

# View results
df.show()
```

## Documentation

### Getting Started

- **[Quick Start](getting-started/index.md)** - Installation and first steps

### User Guides

- **[Catalog Configuration](user-guide/catalogs/index.md)** - Detailed setup for Glue, S3 Tables, REST, SQL, File catalogs
- **[Apache Iceberg](user-guide/iceberg/index.md)** - Iceberg tables, catalogs, and operations
- **[Python API](user-guide/python/index.md)** - Python bindings reference
- **[SQL Reference](user-guide/sql/index.md)** - SQL syntax and functions
- **[Configuration](user-guide/configuration/index.md)** - AWS, S3, and execution settings

## Supported Catalogs

| Catalog | Type | Description |
|---------|------|-------------|
| AWS Glue | `glue` | AWS Glue Data Catalog |
| AWS S3 Tables | `s3tables` | Managed Iceberg tables in S3 |
| REST | `rest` | Iceberg REST catalog |
| SQL | `sql` | Database-backed catalog |
| File | `file` | Local filesystem (testing) |

## SQL Examples

```sql
-- Create Iceberg table
CREATE EXTERNAL TABLE warehouse.db.events (
    id BIGINT,
    event_time TIMESTAMP,
    event_type STRING
)
STORED AS ICEBERG
PARTITIONED BY (day(event_time))
LOCATION 's3://bucket/events';

-- Insert data
INSERT INTO warehouse.db.events
VALUES (1, TIMESTAMP '2024-01-15 10:00:00', 'click');

-- Time travel query
SELECT * FROM warehouse.db.events
TIMESTAMP AS OF '2024-01-14 00:00:00';

-- Merge data
MERGE INTO warehouse.db.users AS target
USING staging.updates AS source
ON target.id = source.id
WHEN MATCHED THEN UPDATE SET name = source.name
WHEN NOT MATCHED THEN INSERT (id, name) VALUES (source.id, source.name);
```

## Installation

### Python

```bash
pip install pathsdata-test
```

### Rust

```toml
[dependencies]
datafusion = { version = "45.0", features = ["iceberg"] }
```

## Requirements

- Python 3.8+ or Rust 1.70+
- AWS credentials (for Glue/S3 Tables)
- Network access to catalog endpoints

## License

PathsData is proprietary software. All rights reserved.

For licensing inquiries, please contact the PathsData team.
