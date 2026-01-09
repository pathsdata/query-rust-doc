# SQL Reference

PathsData supports a comprehensive SQL dialect based on Apache DataFusion with extensions for Iceberg and LanceDB operations.

> **For Iceberg-specific SQL (CREATE TABLE, INSERT, UPDATE, DELETE, MERGE, etc.), see the [Iceberg SQL Reference](iceberg-sql.md)**

## Data Types

### Numeric Types

| Type | Description | Range |
|------|-------------|-------|
| `TINYINT` / `INT8` | 8-bit signed integer | -128 to 127 |
| `SMALLINT` / `INT16` | 16-bit signed integer | -32,768 to 32,767 |
| `INT` / `INTEGER` / `INT32` | 32-bit signed integer | -2B to 2B |
| `BIGINT` / `INT64` | 64-bit signed integer | -9E18 to 9E18 |
| `FLOAT` / `REAL` | 32-bit floating point | ~7 decimal digits |
| `DOUBLE` | 64-bit floating point | ~15 decimal digits |
| `DECIMAL(p, s)` | Fixed-point decimal | Precision up to 38 |

### String Types

| Type | Description |
|------|-------------|
| `VARCHAR` / `STRING` / `TEXT` | Variable-length string |
| `CHAR(n)` | Fixed-length string |

### Date/Time Types

| Type | Description | Example |
|------|-------------|---------|
| `DATE` | Calendar date | `'2024-01-15'` |
| `TIME` | Time of day | `'10:30:00'` |
| `TIMESTAMP` | Date and time | `'2024-01-15 10:30:00'` |
| `INTERVAL` | Time interval | `INTERVAL '1' DAY` |

### Other Types

| Type | Description |
|------|-------------|
| `BOOLEAN` | `TRUE` or `FALSE` |
| `BINARY` / `BYTEA` | Binary data |
| `UUID` | Universally unique identifier |

### Array and Struct Types

```sql
-- Array type
ARRAY<INT>
ARRAY<VARCHAR>

-- Struct type
STRUCT<name VARCHAR, age INT>

-- Map type
MAP<VARCHAR, INT>
```

## DDL Statements

### CREATE TABLE

```sql
-- Basic table
CREATE TABLE catalog.schema.table (
    id BIGINT,
    name VARCHAR,
    created_at TIMESTAMP
);

-- Iceberg table with partitioning
CREATE EXTERNAL TABLE catalog.schema.events (
    id BIGINT,
    event_time TIMESTAMP,
    event_type VARCHAR,
    user_id BIGINT,
    payload VARCHAR
)
STORED AS ICEBERG
PARTITIONED BY (day(event_time), bucket(16, user_id))
LOCATION 's3://bucket/path/events';
```

#### Partition Transforms (Iceberg)

| Transform | Syntax | Description |
|-----------|--------|-------------|
| Identity | `col` | Partition by exact value |
| Year | `year(col)` | Extract year |
| Month | `month(col)` | Extract year-month |
| Day | `day(col)` | Extract year-month-day |
| Hour | `hour(col)` | Extract year-month-day-hour |
| Bucket | `bucket(n, col)` | Hash into n buckets |
| Truncate | `truncate(n, col)` | Truncate strings/numbers |

### DROP TABLE

```sql
DROP TABLE catalog.schema.table;
DROP TABLE IF EXISTS catalog.schema.table;
```

### ALTER TABLE

```sql
-- Add column
ALTER TABLE catalog.schema.table
ADD COLUMN new_col VARCHAR;

-- Drop column
ALTER TABLE catalog.schema.table
DROP COLUMN old_col;

-- Rename column
ALTER TABLE catalog.schema.table
RENAME COLUMN old_name TO new_name;
```

### CREATE SCHEMA

```sql
-- Basic schema
CREATE SCHEMA catalog.my_schema;

-- With properties (Iceberg)
CREATE SCHEMA catalog.analytics WITH (
    'location' = 's3://bucket/analytics/',
    'owner' = 'data-team'
);
```

### DROP SCHEMA

```sql
DROP SCHEMA catalog.my_schema;
DROP SCHEMA IF EXISTS catalog.my_schema CASCADE;
```

### ALTER SCHEMA

```sql
-- Set properties
ALTER SCHEMA catalog.my_schema
SET PROPERTIES ('owner' = 'new-team');

-- Remove properties
ALTER SCHEMA catalog.my_schema
UNSET PROPERTIES ('deprecated');
```

## DML Statements

### SELECT

```sql
-- Basic query
SELECT col1, col2 FROM table;

-- With expressions
SELECT
    col1,
    col2 * 2 AS doubled,
    UPPER(col3) AS upper_name
FROM table;

-- With WHERE
SELECT * FROM table
WHERE status = 'active' AND created_at > '2024-01-01';

-- With JOIN
SELECT a.*, b.name
FROM table_a a
JOIN table_b b ON a.id = b.id;

-- With GROUP BY
SELECT
    category,
    COUNT(*) as count,
    SUM(amount) as total
FROM orders
GROUP BY category
HAVING COUNT(*) > 10;

-- With ORDER BY and LIMIT
SELECT * FROM table
ORDER BY created_at DESC
LIMIT 100 OFFSET 50;

-- With DISTINCT
SELECT DISTINCT category FROM products;

-- Common Table Expressions (CTE)
WITH active_users AS (
    SELECT * FROM users WHERE status = 'active'
)
SELECT * FROM active_users WHERE country = 'US';
```

### INSERT

```sql
-- Insert values
INSERT INTO table (col1, col2, col3)
VALUES (1, 'value', TIMESTAMP '2024-01-15 10:30:00');

-- Insert multiple rows
INSERT INTO table (col1, col2)
VALUES
    (1, 'first'),
    (2, 'second'),
    (3, 'third');

-- Insert from SELECT
INSERT INTO target_table
SELECT * FROM source_table
WHERE condition;

-- Insert with column mapping
INSERT INTO target (id, name, created)
SELECT user_id, user_name, CURRENT_TIMESTAMP
FROM staging;
```

### UPDATE

```sql
-- Basic update
UPDATE table
SET status = 'inactive'
WHERE last_login < '2023-01-01';

-- Update multiple columns
UPDATE users
SET
    status = 'verified',
    verified_at = CURRENT_TIMESTAMP
WHERE email_verified = TRUE;

-- Update with subquery
UPDATE orders o
SET status = 'shipped'
WHERE EXISTS (
    SELECT 1 FROM shipments s
    WHERE s.order_id = o.id
);
```

### DELETE

```sql
-- Basic delete
DELETE FROM table
WHERE status = 'deleted';

-- Delete with date condition
DELETE FROM events
WHERE event_time < TIMESTAMP '2023-01-01 00:00:00';

-- Delete with subquery
DELETE FROM users
WHERE id NOT IN (
    SELECT DISTINCT user_id FROM orders
);
```

### MERGE INTO

```sql
-- Full MERGE syntax
MERGE INTO target_table AS target
USING source_table AS source
ON target.id = source.id
WHEN MATCHED AND source.deleted = TRUE THEN
    DELETE
WHEN MATCHED THEN
    UPDATE SET
        name = source.name,
        updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (id, name, created_at)
    VALUES (source.id, source.name, CURRENT_TIMESTAMP);
```

## Time Travel (Iceberg)

```sql
-- Query at specific snapshot ID
SELECT * FROM table VERSION AS OF 1234567890;

-- Query at timestamp
SELECT * FROM table TIMESTAMP AS OF '2024-01-15 10:00:00';

-- Query from branch
SELECT * FROM table VERSION AS OF 'dev';

-- Query from tag
SELECT * FROM table VERSION AS OF 'v1.0';
```

## Table Maintenance (Iceberg)

### VACUUM

```sql
-- Remove unreferenced data files
VACUUM catalog.schema.table;

-- With retention period
VACUUM catalog.schema.table RETAIN 7 DAYS;
```

### OPTIMIZE

```sql
-- Compact small files
OPTIMIZE catalog.schema.table;

-- Optimize specific partitions
OPTIMIZE catalog.schema.table
WHERE event_date > '2024-01-01';
```

### EXPIRE SNAPSHOTS

```sql
-- Expire old snapshots
EXPIRE SNAPSHOTS catalog.schema.table OLDER THAN '7 days';

-- Keep last N snapshots
EXPIRE SNAPSHOTS catalog.schema.table RETAIN LAST 10;
```

## Branching and Tagging (Iceberg)

```sql
-- Create branch
CREATE BRANCH dev ON catalog.schema.table;

-- Create tag
CREATE TAG v1.0 ON catalog.schema.table;
CREATE TAG v1.0 ON catalog.schema.table AT SNAPSHOT 1234567890;

-- Drop branch/tag
DROP BRANCH dev ON catalog.schema.table;
DROP TAG v1.0 ON catalog.schema.table;
```

## Aggregate Functions

| Function | Description |
|----------|-------------|
| `COUNT(*)` | Count all rows |
| `COUNT(col)` | Count non-null values |
| `COUNT(DISTINCT col)` | Count unique values |
| `SUM(col)` | Sum of values |
| `AVG(col)` | Average value |
| `MIN(col)` | Minimum value |
| `MAX(col)` | Maximum value |
| `STDDEV(col)` | Standard deviation |
| `VARIANCE(col)` | Variance |
| `ARRAY_AGG(col)` | Collect into array |
| `STRING_AGG(col, sep)` | Concatenate strings |

## Window Functions

```sql
SELECT
    id,
    value,
    ROW_NUMBER() OVER (ORDER BY value) as row_num,
    RANK() OVER (PARTITION BY category ORDER BY value) as rank,
    SUM(value) OVER (ORDER BY id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as rolling_sum,
    LAG(value, 1) OVER (ORDER BY id) as prev_value,
    LEAD(value, 1) OVER (ORDER BY id) as next_value
FROM table;
```

| Function | Description |
|----------|-------------|
| `ROW_NUMBER()` | Sequential row number |
| `RANK()` | Rank with gaps |
| `DENSE_RANK()` | Rank without gaps |
| `NTILE(n)` | Divide into n buckets |
| `LAG(col, n)` | Value n rows before |
| `LEAD(col, n)` | Value n rows after |
| `FIRST_VALUE(col)` | First value in window |
| `LAST_VALUE(col)` | Last value in window |
| `SUM/AVG/MIN/MAX` | Aggregates as windows |

## String Functions

| Function | Example | Result |
|----------|---------|--------|
| `LENGTH(s)` | `LENGTH('hello')` | `5` |
| `UPPER(s)` | `UPPER('hello')` | `'HELLO'` |
| `LOWER(s)` | `LOWER('HELLO')` | `'hello'` |
| `TRIM(s)` | `TRIM('  hi  ')` | `'hi'` |
| `LTRIM(s)` | `LTRIM('  hi')` | `'hi'` |
| `RTRIM(s)` | `RTRIM('hi  ')` | `'hi'` |
| `SUBSTRING(s, start, len)` | `SUBSTRING('hello', 2, 3)` | `'ell'` |
| `CONCAT(s1, s2, ...)` | `CONCAT('a', 'b', 'c')` | `'abc'` |
| `REPLACE(s, from, to)` | `REPLACE('hello', 'l', 'x')` | `'hexxo'` |
| `SPLIT_PART(s, delim, n)` | `SPLIT_PART('a-b-c', '-', 2)` | `'b'` |
| `REGEXP_MATCH(s, pat)` | `REGEXP_MATCH('abc123', '[0-9]+')` | `['123']` |
| `REGEXP_REPLACE(s, pat, rep)` | `REGEXP_REPLACE('abc123', '[0-9]', 'X')` | `'abcXXX'` |

## Date/Time Functions

| Function | Description |
|----------|-------------|
| `CURRENT_DATE` | Current date |
| `CURRENT_TIME` | Current time |
| `CURRENT_TIMESTAMP` | Current timestamp |
| `NOW()` | Same as CURRENT_TIMESTAMP |
| `DATE_TRUNC(unit, ts)` | Truncate to unit |
| `DATE_PART(unit, ts)` | Extract part of date |
| `EXTRACT(unit FROM ts)` | Extract part of date |
| `DATE_ADD(ts, interval)` | Add interval to date |
| `DATE_SUB(ts, interval)` | Subtract interval |
| `DATEDIFF(unit, ts1, ts2)` | Difference between dates |
| `TO_TIMESTAMP(s, fmt)` | Parse string to timestamp |

```sql
-- Date/time examples
SELECT
    CURRENT_TIMESTAMP,
    DATE_TRUNC('month', event_time) as month_start,
    EXTRACT(YEAR FROM event_time) as year,
    DATE_ADD(event_time, INTERVAL '1' DAY) as next_day,
    DATEDIFF('day', created_at, CURRENT_TIMESTAMP) as age_days
FROM events;
```

## Conditional Expressions

### CASE

```sql
SELECT
    id,
    CASE status
        WHEN 'A' THEN 'Active'
        WHEN 'I' THEN 'Inactive'
        ELSE 'Unknown'
    END as status_name,
    CASE
        WHEN amount > 1000 THEN 'High'
        WHEN amount > 100 THEN 'Medium'
        ELSE 'Low'
    END as tier
FROM orders;
```

### COALESCE / NULLIF

```sql
-- Return first non-null value
SELECT COALESCE(preferred_name, first_name, 'Unknown') as display_name
FROM users;

-- Return NULL if values are equal
SELECT NULLIF(value, 0) as safe_value
FROM data;
```

### IIF

```sql
SELECT IIF(status = 'active', 'Yes', 'No') as is_active
FROM users;
```

## Operators

### Comparison

| Operator | Description |
|----------|-------------|
| `=` | Equal |
| `<>` or `!=` | Not equal |
| `<`, `>` | Less/greater than |
| `<=`, `>=` | Less/greater or equal |
| `BETWEEN x AND y` | Range check |
| `IN (...)` | List membership |
| `LIKE` | Pattern matching |
| `ILIKE` | Case-insensitive LIKE |
| `IS NULL` | Null check |
| `IS NOT NULL` | Non-null check |

### Logical

| Operator | Description |
|----------|-------------|
| `AND` | Logical AND |
| `OR` | Logical OR |
| `NOT` | Logical NOT |

### Pattern Matching

```sql
-- LIKE patterns
SELECT * FROM users WHERE name LIKE 'John%';     -- Starts with John
SELECT * FROM users WHERE email LIKE '%@gmail.com'; -- Ends with @gmail.com
SELECT * FROM users WHERE code LIKE 'A_B';       -- A, any char, B

-- ILIKE (case-insensitive)
SELECT * FROM users WHERE name ILIKE 'john%';

-- SIMILAR TO (regex-like)
SELECT * FROM users WHERE name SIMILAR TO '(John|Jane)%';

-- Regular expressions
SELECT * FROM logs WHERE message ~ 'error|warning';
```

## Set Operations

```sql
-- Union (removes duplicates)
SELECT * FROM table1
UNION
SELECT * FROM table2;

-- Union All (keeps duplicates)
SELECT * FROM table1
UNION ALL
SELECT * FROM table2;

-- Intersect
SELECT * FROM table1
INTERSECT
SELECT * FROM table2;

-- Except
SELECT * FROM table1
EXCEPT
SELECT * FROM table2;
```

## Joins

```sql
-- Inner join
SELECT * FROM a INNER JOIN b ON a.id = b.a_id;

-- Left outer join
SELECT * FROM a LEFT JOIN b ON a.id = b.a_id;

-- Right outer join
SELECT * FROM a RIGHT JOIN b ON a.id = b.a_id;

-- Full outer join
SELECT * FROM a FULL OUTER JOIN b ON a.id = b.a_id;

-- Cross join
SELECT * FROM a CROSS JOIN b;

-- Natural join
SELECT * FROM a NATURAL JOIN b;

-- Self join
SELECT a.*, b.* FROM employees a
JOIN employees b ON a.manager_id = b.id;
```

## Subqueries

```sql
-- Scalar subquery
SELECT *, (SELECT MAX(value) FROM other) as max_value FROM table;

-- IN subquery
SELECT * FROM orders
WHERE user_id IN (SELECT id FROM users WHERE status = 'active');

-- EXISTS subquery
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);

-- Correlated subquery
SELECT *,
    (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) as order_count
FROM users u;

-- Derived table
SELECT * FROM (
    SELECT category, SUM(amount) as total
    FROM orders
    GROUP BY category
) AS category_totals
WHERE total > 1000;
```

## Next Steps

- [Configuration](../configuration/index.md) - Configuration options
- [Python API](../python/index.md) - Python bindings
- [Iceberg Guide](../iceberg/index.md) - Iceberg-specific SQL
