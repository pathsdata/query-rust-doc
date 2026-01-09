# Iceberg SQL Reference

Complete SQL syntax for Apache Iceberg operations in PathsData.

## CREATE TABLE

Creates a new Iceberg table.

### Syntax

```sql
CREATE EXTERNAL TABLE [IF NOT EXISTS] [catalog.schema.]table_name (
    column_name DATA_TYPE [NOT NULL],
    ...
)
STORED AS ICEBERG
[PARTITIONED BY (partition_spec, ...)]
[LOCATION 'path']
[OPTIONS ('key' 'value', ...)]
```

### Clauses

| Clause | Required | Default | Description |
|--------|----------|---------|-------------|
| `EXTERNAL` | **Yes** | - | Required for Iceberg tables |
| `IF NOT EXISTS` | No | - | Skip if table already exists |
| Column definitions | **Yes** | - | At least one column required |
| `STORED AS ICEBERG` | **Yes** | - | Specifies Iceberg format |
| `PARTITIONED BY` | No | - | Partition specification |
| `LOCATION` | No | `{namespace}/{table}` | Storage path - auto-generated if omitted |
| `OPTIONS` | No | - | Table properties |

**Note**: When `LOCATION` is omitted, the table location is automatically generated as `{namespace}/{table_name}` relative to the catalog's warehouse path.

### Partition Transforms

| Transform | Syntax | Description |
|-----------|--------|-------------|
| Identity | `column` or `identity(column)` | Partition by exact value |
| Year | `year(column)` | Extract year from timestamp/date |
| Month | `month(column)` | Extract year-month |
| Day | `day(column)` | Extract year-month-day |
| Hour | `hour(column)` | Extract year-month-day-hour |
| Bucket | `bucket(n, column)` | Hash into n buckets |
| Truncate | `truncate(n, column)` | Truncate to width n |

### Table Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `write.format.default` | `parquet`, `avro`, `orc` | `parquet` | File format |
| `write.delete.mode` | `copy-on-write`, `merge-on-read` | `copy-on-write` | Delete strategy |
| `write.update.mode` | `copy-on-write`, `merge-on-read` | `copy-on-write` | Update strategy |
| `write.delete.file.type` | `position`, `equality` | `position` | Delete file type (MOR only) |

### Examples

#### Basic Table (No Location - Auto-Generated)

```sql
-- Location auto-generated as: {warehouse_path}/db/users
CREATE EXTERNAL TABLE warehouse.db.users (
    id BIGINT NOT NULL,
    name VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP
)
STORED AS ICEBERG
```

#### With Explicit Location

```sql
CREATE EXTERNAL TABLE warehouse.db.users (
    id BIGINT NOT NULL,
    name VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP
)
STORED AS ICEBERG
LOCATION 's3://my-bucket/custom/path/users'
```

#### With Partitioning

```sql
CREATE EXTERNAL TABLE warehouse.db.events (
    id BIGINT NOT NULL,
    event_time TIMESTAMP NOT NULL,
    event_type VARCHAR,
    user_id BIGINT,
    payload VARCHAR
)
STORED AS ICEBERG
PARTITIONED BY (day(event_time))
```

#### Multiple Partition Columns

```sql
CREATE EXTERNAL TABLE warehouse.db.sales (
    id BIGINT NOT NULL,
    sale_date DATE NOT NULL,
    region VARCHAR NOT NULL,
    product_id BIGINT,
    amount DECIMAL(10,2)
)
STORED AS ICEBERG
PARTITIONED BY (year(sale_date), region)
LOCATION 's3://my-bucket/warehouse/sales'
```

#### With Merge-on-Read

```sql
CREATE EXTERNAL TABLE warehouse.db.updates_heavy (
    id BIGINT NOT NULL,
    data VARCHAR,
    updated_at TIMESTAMP
)
STORED AS ICEBERG
LOCATION 's3://my-bucket/warehouse/updates_heavy'
OPTIONS (
    'write.delete.mode' 'merge-on-read',
    'write.update.mode' 'merge-on-read'
)
```

#### If Not Exists

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS warehouse.db.logs (
    id BIGINT NOT NULL,
    message VARCHAR,
    level VARCHAR,
    ts TIMESTAMP
)
STORED AS ICEBERG
PARTITIONED BY (day(ts))
LOCATION 's3://my-bucket/warehouse/logs'
```

---

## DROP TABLE

Drops an Iceberg table and optionally its data.

### Syntax

```sql
DROP TABLE [IF EXISTS] [catalog.schema.]table_name
```

### Clauses

| Clause | Required | Description |
|--------|----------|-------------|
| `IF EXISTS` | No | Skip if table doesn't exist |
| Table name | **Yes** | Fully qualified or simple name |

### Examples

```sql
-- Basic drop
DROP TABLE warehouse.db.old_table

-- Safe drop
DROP TABLE IF EXISTS warehouse.db.maybe_exists
```

---

## ALTER TABLE

Modifies table schema or properties.

### Add Column

```sql
ALTER TABLE [catalog.schema.]table_name
ADD COLUMN column_name DATA_TYPE [NOT NULL]
```

### Drop Column

```sql
ALTER TABLE [catalog.schema.]table_name
DROP COLUMN [IF EXISTS] column_name
```

### Rename Column

```sql
ALTER TABLE [catalog.schema.]table_name
RENAME COLUMN old_name TO new_name
```

### Set Properties

```sql
ALTER TABLE [catalog.schema.]table_name
SET TBLPROPERTIES ('key1' = 'value1', 'key2' = 'value2')
```

### Unset Properties

```sql
ALTER TABLE [catalog.schema.]table_name
UNSET TBLPROPERTIES ('key1', 'key2')
```

### Examples

```sql
-- Add column
ALTER TABLE warehouse.db.users
ADD COLUMN phone VARCHAR

-- Add non-null column
ALTER TABLE warehouse.db.users
ADD COLUMN status VARCHAR NOT NULL

-- Drop column
ALTER TABLE warehouse.db.users
DROP COLUMN IF EXISTS deprecated_field

-- Rename column
ALTER TABLE warehouse.db.users
RENAME COLUMN phone TO phone_number

-- Change properties
ALTER TABLE warehouse.db.events
SET TBLPROPERTIES ('write.delete.mode' = 'merge-on-read')
```

---

## INSERT

Inserts data into an Iceberg table.

### Syntax (VALUES)

```sql
INSERT INTO [catalog.schema.]table_name [(column1, column2, ...)]
VALUES
    (value1, value2, ...),
    (value1, value2, ...),
    ...
```

### Syntax (SELECT)

```sql
INSERT INTO [catalog.schema.]table_name [(column1, column2, ...)]
SELECT ... FROM ...
```

### Clauses

| Clause | Required | Description |
|--------|----------|-------------|
| `INSERT INTO` | **Yes** | Target table |
| Column list | No | If omitted, uses all columns in order |
| `VALUES` or `SELECT` | **Yes** | Data source |

### Examples

#### Insert Values

```sql
INSERT INTO warehouse.db.users (id, name, email, created_at)
VALUES
    (1, 'Alice', 'alice@example.com', TIMESTAMP '2024-01-15 10:00:00'),
    (2, 'Bob', 'bob@example.com', TIMESTAMP '2024-01-15 11:00:00'),
    (3, 'Charlie', 'charlie@example.com', TIMESTAMP '2024-01-15 12:00:00')
```

#### Insert from SELECT

```sql
INSERT INTO warehouse.db.users_archive
SELECT * FROM warehouse.db.users
WHERE created_at < TIMESTAMP '2023-01-01 00:00:00'
```

#### Insert with Column Mapping

```sql
INSERT INTO warehouse.db.summary (user_id, total_orders, last_order)
SELECT
    user_id,
    COUNT(*) as total_orders,
    MAX(order_date) as last_order
FROM warehouse.db.orders
GROUP BY user_id
```

---

## UPDATE

Updates existing rows in an Iceberg table.

### Basic Syntax

```sql
UPDATE [catalog.schema.]table_name
SET column1 = expression1,
    column2 = expression2,
    ...
[WHERE condition]
```

### UPDATE with FROM (Join)

```sql
UPDATE [catalog.schema.]table_name
SET column1 = source.column1,
    column2 = source.column2,
    ...
FROM [catalog.schema.]source_table [AS alias]
WHERE join_condition
```

### Clauses

| Clause | Required | Description |
|--------|----------|-------------|
| `UPDATE` | **Yes** | Target table |
| `SET` | **Yes** | Column assignments |
| `WHERE` | No | If omitted, updates ALL rows |
| `FROM` | No | For join-based updates |

### Examples

#### Simple Update

```sql
UPDATE warehouse.db.users
SET status = 'inactive'
WHERE last_login < TIMESTAMP '2023-01-01 00:00:00'
```

#### Update with Expression

```sql
UPDATE warehouse.db.products
SET price = price * 1.10,
    updated_at = CURRENT_TIMESTAMP
WHERE category = 'electronics'
```

#### Update All Rows

```sql
-- WARNING: Updates every row!
UPDATE warehouse.db.config
SET version = 2
```

#### Update with JOIN (FROM clause)

```sql
UPDATE warehouse.db.orders
SET status = u.new_status,
    updated_at = CURRENT_TIMESTAMP
FROM warehouse.db.order_updates AS u
WHERE warehouse.db.orders.id = u.order_id
```

#### Update with Composite Key Join

```sql
UPDATE warehouse.db.inventory
SET quantity = s.new_quantity
FROM warehouse.db.stock_updates AS s
WHERE warehouse.db.inventory.product_id = s.product_id
  AND warehouse.db.inventory.warehouse_id = s.warehouse_id
```

---

## DELETE

Deletes rows from an Iceberg table.

### Syntax

```sql
DELETE FROM [catalog.schema.]table_name
[WHERE condition]
```

### Clauses

| Clause | Required | Description |
|--------|----------|-------------|
| `DELETE FROM` | **Yes** | Target table |
| `WHERE` | No | If omitted, deletes ALL rows |

### Examples

#### Delete with Condition

```sql
DELETE FROM warehouse.db.users
WHERE status = 'deleted'
```

#### Delete Old Data

```sql
DELETE FROM warehouse.db.events
WHERE event_time < TIMESTAMP '2022-01-01 00:00:00'
```

#### Delete with IN

```sql
DELETE FROM warehouse.db.products
WHERE id IN (101, 102, 103)
```

#### Delete All Rows

```sql
-- WARNING: Deletes everything!
DELETE FROM warehouse.db.temp_table
```

---

## MERGE INTO

Performs upsert operations (insert, update, delete in one statement).

### Syntax

```sql
MERGE INTO [catalog.schema.]target_table [AS target_alias]
USING (source_query | source_table) [AS source_alias]
ON join_condition
[WHEN MATCHED [AND condition] THEN UPDATE SET col1 = expr1, ...]
[WHEN MATCHED [AND condition] THEN DELETE]
[WHEN NOT MATCHED [AND condition] THEN INSERT (col1, ...) VALUES (expr1, ...)]
```

### Clauses

| Clause | Required | Description |
|--------|----------|-------------|
| `MERGE INTO` | **Yes** | Target table |
| `USING` | **Yes** | Source data (table or subquery) |
| `ON` | **Yes** | Join condition |
| `WHEN MATCHED ... UPDATE` | No | Update matching rows |
| `WHEN MATCHED ... DELETE` | No | Delete matching rows |
| `WHEN NOT MATCHED ... INSERT` | No | Insert non-matching rows |

**Note**: At least one WHEN clause is required.

### Examples

#### Basic Upsert

```sql
MERGE INTO warehouse.db.users AS target
USING warehouse.db.user_updates AS source
ON target.id = source.id
WHEN MATCHED THEN
    UPDATE SET
        name = source.name,
        email = source.email,
        updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (id, name, email, created_at)
    VALUES (source.id, source.name, source.email, CURRENT_TIMESTAMP)
```

#### MERGE with Subquery Source

```sql
MERGE INTO warehouse.db.summary AS t
USING (
    SELECT user_id, COUNT(*) as order_count, SUM(amount) as total
    FROM warehouse.db.orders
    WHERE order_date >= '2024-01-01'
    GROUP BY user_id
) AS s
ON t.user_id = s.user_id
WHEN MATCHED THEN
    UPDATE SET order_count = s.order_count, total = s.total
WHEN NOT MATCHED THEN
    INSERT (user_id, order_count, total)
    VALUES (s.user_id, s.order_count, s.total)
```

#### MERGE with DELETE

```sql
MERGE INTO warehouse.db.products AS target
USING warehouse.db.product_changes AS source
ON target.id = source.id
WHEN MATCHED AND source.action = 'delete' THEN
    DELETE
WHEN MATCHED AND source.action = 'update' THEN
    UPDATE SET
        name = source.name,
        price = source.price
WHEN NOT MATCHED AND source.action = 'insert' THEN
    INSERT (id, name, price)
    VALUES (source.id, source.name, source.price)
```

#### MERGE with Composite Key

```sql
MERGE INTO warehouse.db.meter_readings AS t
USING warehouse.db.new_readings AS s
ON t.meter_id = s.meter_id AND t.reading_time = s.reading_time
WHEN MATCHED THEN
    UPDATE SET value = s.value, updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (meter_id, reading_time, value, created_at)
    VALUES (s.meter_id, s.reading_time, s.value, CURRENT_TIMESTAMP)
```

---

## Time Travel

Query historical data using snapshots.

### By Snapshot ID

```sql
SELECT * FROM [catalog.schema.]table_name
VERSION AS OF snapshot_id
```

### By Timestamp

```sql
SELECT * FROM [catalog.schema.]table_name
TIMESTAMP AS OF 'timestamp'
```

### By Branch/Tag

```sql
SELECT * FROM [catalog.schema.]table_name
VERSION AS OF 'branch_or_tag_name'
```

### Examples

```sql
-- Query specific snapshot
SELECT * FROM warehouse.db.users
VERSION AS OF 1234567890123456789

-- Query at timestamp
SELECT * FROM warehouse.db.users
TIMESTAMP AS OF '2024-01-15 10:00:00'

-- Query from branch
SELECT * FROM warehouse.db.users
VERSION AS OF 'dev'

-- Query from tag
SELECT * FROM warehouse.db.users
VERSION AS OF 'v1.0'
```

---

## Table Maintenance

### VACUUM

Remove orphaned files not referenced by any snapshot.

```sql
VACUUM [catalog.schema.]table_name
[OLDER_THAN days]
[DRY_RUN]
```

| Option | Description |
|--------|-------------|
| `OLDER_THAN days` | Only clean files older than N days |
| `DRY_RUN` | Report files without deleting |

```sql
-- Basic vacuum
VACUUM warehouse.db.events

-- Only files older than 14 days
VACUUM warehouse.db.events OLDER_THAN 14

-- Preview what would be deleted
VACUUM warehouse.db.events OLDER_THAN 7 DRY_RUN
```

### EXPIRE SNAPSHOTS

Remove old snapshots to save storage.

```sql
EXPIRE SNAPSHOTS [catalog.schema.]table_name
[OLDER_THAN days]
[RETAIN count]
```

| Option | Description |
|--------|-------------|
| `OLDER_THAN days` | Expire snapshots older than N days |
| `RETAIN count` | Keep at least N snapshots |

```sql
-- Expire old snapshots
EXPIRE SNAPSHOTS warehouse.db.events OLDER_THAN 30

-- Keep minimum snapshots
EXPIRE SNAPSHOTS warehouse.db.events RETAIN 10

-- Both options
EXPIRE SNAPSHOTS warehouse.db.events OLDER_THAN 30 RETAIN 5
```

### OPTIMIZE

Compact small files for better read performance.

```sql
OPTIMIZE [catalog.schema.]table_name
[WHERE condition]
```

```sql
-- Optimize entire table
OPTIMIZE warehouse.db.events

-- Optimize specific partitions
OPTIMIZE warehouse.db.events
WHERE event_date >= '2024-01-01'
```

---

## Branching and Tagging

### Create Branch

```sql
CREATE BRANCH [IF NOT EXISTS] branch_name
ON [catalog.schema.]table_name
[AS OF SNAPSHOT snapshot_id]
```

```sql
-- Create branch at current snapshot
CREATE BRANCH dev ON warehouse.db.users

-- Create branch at specific snapshot
CREATE BRANCH feature_x ON warehouse.db.users
AS OF SNAPSHOT 1234567890
```

### Drop Branch

```sql
DROP BRANCH [IF EXISTS] branch_name
ON [catalog.schema.]table_name
```

### Create Tag

```sql
CREATE TAG [IF NOT EXISTS] tag_name
ON [catalog.schema.]table_name
AS OF SNAPSHOT snapshot_id
```

```sql
-- Create tag at specific snapshot
CREATE TAG v1.0 ON warehouse.db.users
AS OF SNAPSHOT 1234567890
```

### Drop Tag

```sql
DROP TAG [IF EXISTS] tag_name
ON [catalog.schema.]table_name
```

---

## Namespace (Schema) Management

### Create Schema

```sql
CREATE SCHEMA [IF NOT EXISTS] catalog.schema_name
[WITH PROPERTIES ('key' 'value', ...)]
```

```sql
-- Basic schema
CREATE SCHEMA warehouse.analytics

-- With properties
CREATE SCHEMA warehouse.analytics WITH PROPERTIES (
    'location' 's3://bucket/analytics/',
    'owner' 'data-team'
)
```

### Drop Schema

```sql
DROP SCHEMA [IF EXISTS] catalog.schema_name [CASCADE]
```

```sql
-- Drop empty schema
DROP SCHEMA warehouse.old_schema

-- Drop schema and all tables
DROP SCHEMA warehouse.old_schema CASCADE
```

### Alter Schema

```sql
ALTER SCHEMA catalog.schema_name
SET TBLPROPERTIES ('key' = 'value', ...)
```

### Describe Schema

```sql
DESCRIBE SCHEMA catalog.schema_name
```

---

## Data Types Reference

| SQL Type | Description | Example |
|----------|-------------|---------|
| `BOOLEAN` | True/false | `TRUE`, `FALSE` |
| `TINYINT` / `INT8` | 8-bit integer | `127` |
| `SMALLINT` / `INT16` | 16-bit integer | `32767` |
| `INT` / `INTEGER` | 32-bit integer | `2147483647` |
| `BIGINT` / `INT64` | 64-bit integer | `9223372036854775807` |
| `FLOAT` / `REAL` | 32-bit float | `3.14` |
| `DOUBLE` | 64-bit float | `3.141592653589793` |
| `DECIMAL(p,s)` | Fixed precision | `DECIMAL(10,2)` |
| `VARCHAR` / `STRING` | Variable string | `'hello'` |
| `DATE` | Calendar date | `DATE '2024-01-15'` |
| `TIME` | Time of day | `TIME '10:30:00'` |
| `TIMESTAMP` | Date and time | `TIMESTAMP '2024-01-15 10:30:00'` |
| `BINARY` | Binary data | - |
| `UUID` | UUID type | - |

---

## Quick Reference

| Operation | Required Clauses | Optional Clauses |
|-----------|-----------------|------------------|
| CREATE TABLE | `EXTERNAL`, `STORED AS ICEBERG` | `LOCATION`, `PARTITIONED BY`, `OPTIONS` |
| DROP TABLE | Table name | `IF EXISTS` |
| INSERT | `INTO`, `VALUES` or `SELECT` | Column list |
| UPDATE | `SET` | `WHERE`, `FROM` |
| DELETE | `FROM` | `WHERE` |
| MERGE | `USING`, `ON`, ≥1 `WHEN` clause | Multiple `WHEN` clauses |
| VACUUM | Table name | `OLDER_THAN`, `DRY_RUN` |
| EXPIRE SNAPSHOTS | Table name | `OLDER_THAN`, `RETAIN` |

## Next Steps

- [Catalog Configuration](../catalogs/index.md) - Configure catalog connections
- [Python API](../python/index.md) - Execute SQL from Python
- [Configuration](../configuration/index.md) - Tuning options
