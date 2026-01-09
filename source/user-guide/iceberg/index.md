# Apache Iceberg User Guide

PathsData provides native Apache Iceberg support with full read/write capabilities, ACID transactions, and time travel queries.

## Supported Catalogs

| Catalog | Type | Description |
|---------|------|-------------|
| **AWS Glue** | `glue` | AWS Glue Data Catalog (most common for AWS) |
| **AWS S3 Tables** | `s3tables` | Managed Iceberg tables in S3 |
| **REST** | `rest` | Iceberg REST catalog (Tabular, Nessie, etc.) |
| **SQL** | `sql` | Database-backed catalog (PostgreSQL, SQLite) |
| **File** | `file` | Local filesystem (for testing) |

## Registering Catalogs

### AWS Glue Catalog

```python
from pathsdata_test import SessionContext

ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"
})

ctx.register_iceberg("warehouse", {
    "type": "glue",
    "glue.region": "us-east-1"
})
```

### AWS S3 Tables

```python
ctx.register_iceberg("s3tables", {
    "type": "s3tables",
    "s3tables.table-bucket-arn": "arn:aws:s3tables:us-east-1:123456789012:bucket/my-bucket",
    "s3tables.region": "us-east-1"
})
```

### REST Catalog

```python
ctx.register_iceberg("rest_catalog", {
    "type": "rest",
    "uri": "https://my-catalog.example.com",
    "rest.token": "your-bearer-token"
})
```

### SQL Catalog

```python
ctx.register_iceberg("sql_catalog", {
    "type": "sql",
    "uri": "postgresql://user:pass@localhost/iceberg"
})
```

### File Catalog (Local Testing)

```python
ctx.register_iceberg("local", {
    "type": "file",
    "warehouse": "/path/to/warehouse"
})
```

## Table Operations

### Creating Tables

```sql
-- Basic table (location auto-generated)
CREATE EXTERNAL TABLE warehouse.analytics.events (
    id BIGINT,
    event_time TIMESTAMP,
    event_type STRING,
    user_id BIGINT,
    payload STRING
)
STORED AS ICEBERG
PARTITIONED BY (day(event_time))

-- With explicit location
CREATE EXTERNAL TABLE warehouse.analytics.events (
    id BIGINT,
    event_time TIMESTAMP,
    event_type STRING,
    user_id BIGINT,
    payload STRING
)
STORED AS ICEBERG
PARTITIONED BY (day(event_time))
LOCATION 's3://my-bucket/analytics/events'
```

**Note**: `LOCATION` is optional. If omitted, the table location is auto-generated as `{namespace}/{table_name}`.

### Partition Transforms

| Transform | Example | Description |
|-----------|---------|-------------|
| `identity` | `PARTITIONED BY (region)` | Exact value |
| `year` | `PARTITIONED BY (year(ts))` | Year extraction |
| `month` | `PARTITIONED BY (month(ts))` | Year + Month |
| `day` | `PARTITIONED BY (day(ts))` | Year + Month + Day |
| `hour` | `PARTITIONED BY (hour(ts))` | Year + Month + Day + Hour |
| `bucket` | `PARTITIONED BY (bucket(16, id))` | Hash bucketing |
| `truncate` | `PARTITIONED BY (truncate(10, name))` | String truncation |

### Dropping Tables

```sql
DROP TABLE warehouse.analytics.events;
DROP TABLE IF EXISTS warehouse.analytics.events;
```

## DML Operations

### INSERT

```sql
INSERT INTO warehouse.analytics.events
VALUES (1, TIMESTAMP '2024-01-15 10:30:00', 'click', 100, '{}');

-- Insert from SELECT
INSERT INTO warehouse.analytics.events
SELECT * FROM staging.new_events;
```

### UPDATE

```sql
UPDATE warehouse.analytics.events
SET event_type = 'view'
WHERE event_type = 'pageview';

-- Update with subquery
UPDATE warehouse.analytics.users AS u
SET status = 'active'
WHERE EXISTS (
    SELECT 1 FROM warehouse.analytics.events e
    WHERE e.user_id = u.id AND e.event_time > TIMESTAMP '2024-01-01'
);
```

### DELETE

```sql
DELETE FROM warehouse.analytics.events
WHERE event_time < TIMESTAMP '2023-01-01';

-- Delete with subquery
DELETE FROM warehouse.analytics.users
WHERE id NOT IN (
    SELECT DISTINCT user_id FROM warehouse.analytics.events
);
```

### MERGE INTO

```sql
MERGE INTO warehouse.analytics.users AS target
USING staging.user_updates AS source
ON target.id = source.id
WHEN MATCHED THEN
    UPDATE SET
        name = source.name,
        email = source.email,
        updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (id, name, email, created_at)
    VALUES (source.id, source.name, source.email, CURRENT_TIMESTAMP);
```

## Time Travel

### Query at Snapshot

```sql
-- Query specific snapshot
SELECT * FROM warehouse.db.table VERSION AS OF 123456789;

-- Query at timestamp
SELECT * FROM warehouse.db.table TIMESTAMP AS OF '2024-01-15 10:00:00';
```

### Python API

```python
from pathsdata_test import SessionContext

ctx = SessionContext({"aws.region": "us-east-1"})
ctx.register_iceberg("warehouse", {"type": "glue"})

# Query at specific snapshot
df = ctx.sql("""
    SELECT * FROM warehouse.db.users
    VERSION AS OF 1234567890
""")
```

## Schema Evolution

### Add Columns

```sql
ALTER TABLE warehouse.db.users
ADD COLUMN phone STRING;

ALTER TABLE warehouse.db.users
ADD COLUMN address STRING AFTER email;
```

### Drop Columns

```sql
ALTER TABLE warehouse.db.users
DROP COLUMN phone;
```

### Rename Columns

```sql
ALTER TABLE warehouse.db.users
RENAME COLUMN phone TO phone_number;
```

## Table Maintenance

### VACUUM

Remove old data files that are no longer referenced:

```sql
VACUUM warehouse.db.users
VACUUM warehouse.db.users OLDER_THAN 7
VACUUM warehouse.db.users OLDER_THAN 7 DRY_RUN
```

### OPTIMIZE

Compact small files for better read performance:

```sql
OPTIMIZE warehouse.db.users;
OPTIMIZE warehouse.db.users WHERE event_date > '2024-01-01';
```

### EXPIRE SNAPSHOTS

Remove old snapshots to save storage:

```sql
EXPIRE SNAPSHOTS warehouse.db.users OLDER_THAN 7
EXPIRE SNAPSHOTS warehouse.db.users RETAIN 10
EXPIRE SNAPSHOTS warehouse.db.users OLDER_THAN 30 RETAIN 5
```

## Branching and Tagging

### Branches

```sql
-- Create a branch
CREATE BRANCH dev ON warehouse.db.users;

-- Query from branch
SELECT * FROM warehouse.db.users VERSION AS OF 'dev';

-- Drop branch
DROP BRANCH dev ON warehouse.db.users;
```

### Tags

```sql
-- Create tag at specific snapshot
CREATE TAG v1.0 ON warehouse.db.users AS OF SNAPSHOT 1234567890

-- Query from tag
SELECT * FROM warehouse.db.users VERSION AS OF 'v1.0'

-- Drop tag
DROP TAG v1.0 ON warehouse.db.users
```

## Namespace Management

### Create Namespace

```sql
CREATE SCHEMA warehouse.analytics

CREATE SCHEMA warehouse.analytics WITH PROPERTIES (
    'location' 's3://my-bucket/analytics/',
    'owner' 'data-team'
)
```

### Describe Namespace

```sql
DESCRIBE SCHEMA warehouse.analytics;
```

### Alter Namespace

```sql
ALTER SCHEMA warehouse.analytics
SET TBLPROPERTIES ('owner' = 'analytics-team')

ALTER SCHEMA warehouse.analytics
UNSET TBLPROPERTIES ('deprecated')
```

### Drop Namespace

```sql
DROP SCHEMA warehouse.analytics
DROP SCHEMA warehouse.analytics CASCADE
```

## Configuration Priority

Credentials are resolved in this order:

1. **Catalog-specific** (`glue.access-key-id`)
2. **S3 config** (`s3.access-key-id`)
3. **Session config** (`SET aws.access_key_id`)
4. **AWS SDK chain**:
   - Environment variables
   - ~/.aws/credentials
   - ~/.aws/config (SSO)
   - Web identity token (Kubernetes)
   - ECS task role
   - EC2 instance profile

## Next Steps

- [SQL Reference](../sql/index.md) - Complete SQL syntax
- [Configuration](../configuration/index.md) - Performance tuning
- [Python API](../python/index.md) - Python bindings
