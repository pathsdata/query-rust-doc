# Configuration Reference

PATHSDATA provides flexible configuration options for AWS credentials, S3 access, query execution, and catalog settings.

## Configuration Hierarchy

Configuration is resolved in the following priority order (highest to lowest):

1. **Catalog-specific config** - Settings passed directly to `register_iceberg()`
2. **Session config** - Settings passed to `SessionContext()`
3. **Environment variables** - Standard AWS environment variables
4. **AWS SDK credential chain** - Profiles, SSO, IAM roles, etc.

## AWS Configuration

### Session-Level AWS Config

```python
from pathsdata_test import SessionContext

ctx = SessionContext({
    # Region (required for most AWS services)
    "aws.region": "us-east-1",

    # Authentication options (choose one):

    # Option 1: Use AWS profile
    "aws.profile_name": "my-profile",

    # Option 2: Explicit credentials
    "aws.access_key_id": "AKIA...",
    "aws.secret_access_key": "...",
    "aws.session_token": "...",  # Optional, for temporary credentials

    # Option 3: Role assumption
    "aws.role_arn": "arn:aws:iam::123456789012:role/MyRole",
    "aws.role_session_name": "pathsdata-session",

    # Custom endpoint (for LocalStack, MinIO, etc.)
    "aws.endpoint": "http://localhost:4566"
})
```

### AWS Options Reference

| Option | Type | Description |
|--------|------|-------------|
| `aws.region` | string | AWS region (e.g., "us-east-1") |
| `aws.profile_name` | string | AWS profile from ~/.aws/credentials or ~/.aws/config |
| `aws.access_key_id` | string | AWS access key ID |
| `aws.secret_access_key` | string | AWS secret access key |
| `aws.session_token` | string | Session token for temporary credentials |
| `aws.role_arn` | string | IAM role ARN for role assumption |
| `aws.role_session_name` | string | Session name when assuming role |
| `aws.endpoint` | string | Custom AWS endpoint URL |

### AWS Credential Chain

When explicit credentials are not provided, PATHSDATA uses the AWS SDK credential chain:

1. **Environment variables**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`
   - `AWS_REGION` / `AWS_DEFAULT_REGION`

2. **Shared credentials file** (`~/.aws/credentials`)
   ```ini
   [default]
   aws_access_key_id = AKIA...
   aws_secret_access_key = ...

   [my-profile]
   aws_access_key_id = AKIA...
   aws_secret_access_key = ...
   ```

3. **AWS config file** (`~/.aws/config`)
   ```ini
   [default]
   region = us-east-1

   [profile my-profile]
   region = us-west-2
   role_arn = arn:aws:iam::123456789012:role/MyRole
   source_profile = default

   [profile sso-profile]
   sso_start_url = https://my-sso.awsapps.com/start
   sso_region = us-east-1
   sso_account_id = 123456789012
   sso_role_name = MyRole
   region = us-west-2
   ```

4. **Web identity token** (Kubernetes/EKS)
   - Uses `AWS_WEB_IDENTITY_TOKEN_FILE` and `AWS_ROLE_ARN`

5. **ECS container credentials**
   - Automatic in AWS ECS tasks

6. **EC2 instance metadata** (IMDS)
   - Automatic on EC2 instances with IAM roles

## S3 Configuration

### Connection Pool Settings

```python
ctx = SessionContext({
    "aws.region": "us-east-1",

    # S3 connection tuning
    "s3.max_connections": 16,         # Max concurrent connections (default: 16)
    "s3.connect_timeout": 30,         # Connection timeout in seconds
    "s3.read_timeout": 60,            # Read timeout in seconds
    "s3.retry_max_attempts": 3,       # Max retry attempts

    # S3-specific endpoint (separate from aws.endpoint)
    "s3.endpoint": "https://s3.us-west-2.amazonaws.com",
    "s3.region": "us-west-2"          # Override region for S3 only
})
```

### S3 Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `s3.max_connections` | int | 16 | Maximum concurrent S3 connections |
| `s3.connect_timeout` | int | 30 | Connection timeout (seconds) |
| `s3.read_timeout` | int | 60 | Read timeout (seconds) |
| `s3.region` | string | - | S3-specific region override |
| `s3.endpoint` | string | - | Custom S3 endpoint |
| `s3.access_key_id` | string | - | S3-specific access key |
| `s3.secret_access_key` | string | - | S3-specific secret key |

## Catalog Configuration

### Glue Catalog

```python
ctx.register_iceberg("warehouse", {
    "type": "glue",

    # Glue-specific settings
    "glue.region": "us-east-1",           # Region for Glue API
    "glue.access-key-id": "AKIA...",      # Glue-specific credentials
    "glue.secret-access-key": "...",
    "glue.endpoint": "https://...",       # Custom Glue endpoint

    # S3 settings for data files (optional, inherits from session)
    "s3.region": "us-east-1",
    "s3.endpoint": "https://..."
})
```

### S3 Tables Catalog

```python
ctx.register_iceberg("s3tables", {
    "type": "s3tables",

    # Required: S3 Tables bucket ARN
    "s3tables.table-bucket-arn": "arn:aws:s3tables:us-east-1:123456789012:bucket/my-bucket",

    # Region (required)
    "s3tables.region": "us-east-1",

    # Optional: Override credentials for this catalog
    "s3tables.access-key-id": "AKIA...",
    "s3tables.secret-access-key": "..."
})
```

### REST Catalog

```python
ctx.register_iceberg("rest", {
    "type": "rest",

    # REST catalog endpoint
    "uri": "https://catalog.example.com",

    # Authentication
    "rest.token": "bearer-token",            # Bearer token
    # OR
    "rest.credential": "client:secret",      # OAuth client credentials

    # Optional settings
    "rest.prefix": "my-warehouse",           # Warehouse prefix
    "rest.headers": "X-Custom: value",       # Custom headers

    # S3 settings (for data files)
    "s3.region": "us-east-1",
    "s3.access-key-id": "...",
    "s3.secret-access-key": "..."
})
```

### SQL Catalog

```python
ctx.register_iceberg("sql", {
    "type": "sql",

    # Database connection URI
    "uri": "postgresql://user:pass@localhost:5432/iceberg",
    # OR
    "uri": "sqlite:///path/to/catalog.db",

    # Optional: default warehouse location
    "warehouse": "s3://my-bucket/warehouse/",

    # S3 settings (for data files)
    "s3.region": "us-east-1"
})
```

### File Catalog

```python
# Local filesystem (for testing)
ctx.register_iceberg("local", {
    "type": "file",
    "warehouse": "/path/to/warehouse"
})

# S3-backed file catalog
ctx.register_iceberg("s3file", {
    "type": "file",
    "warehouse": "s3://my-bucket/warehouse/",
    "s3.region": "us-east-1"
})
```

## LanceDB Configuration

```python
# Local LanceDB
ctx.register_lancedb("vectors", {
    "uri": "/path/to/lancedb"
})

# S3-backed LanceDB
ctx.register_lancedb("vectors", {
    "uri": "s3://my-bucket/lancedb/",
    "s3.region": "us-east-1"
})
```

## Query Execution Configuration

### Memory and Parallelism

```python
ctx = SessionContext({
    # Execution settings
    "datafusion.execution.target_partitions": 8,
    "datafusion.execution.batch_size": 8192,

    # Memory settings
    "datafusion.execution.memory_limit": "4GB",
    "datafusion.execution.sort_spill_reservation_bytes": 10485760,

    # Parquet settings
    "datafusion.execution.parquet.pushdown_filters": True,
    "datafusion.execution.parquet.reorder_filters": True,
    "datafusion.execution.parquet.enable_page_index": True
})
```

### Execution Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `target_partitions` | int | CPU cores | Parallelism level |
| `batch_size` | int | 8192 | Rows per batch |
| `memory_limit` | string | - | Memory limit (e.g., "4GB") |
| `coalesce_batches` | bool | true | Combine small batches |
| `collect_statistics` | bool | true | Collect query statistics |

### Parquet Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pushdown_filters` | bool | true | Push filters to Parquet reader |
| `reorder_filters` | bool | true | Optimize filter order |
| `enable_page_index` | bool | true | Use page-level statistics |
| `pruning` | bool | true | Enable row group pruning |
| `bloom_filter_on_read` | bool | true | Use bloom filters |

## Iceberg Streaming Configuration

Control read/write parallelism and performance for Iceberg tables using session-level settings.

### Setting Iceberg Options

```python
# Via SessionContext configuration
ctx = SessionContext({
    "iceberg.max_concurrent_files": 16,
    "iceberg.max_concurrent_partitions": 32,
    "iceberg.max_concurrent_writers": 10,
    "iceberg.buffer_size": 4,
    "iceberg.parallel_manifest_reads": True
})

# Or via SQL SET commands
ctx.sql("SET iceberg.max_concurrent_files = 16")
ctx.sql("SET iceberg.max_concurrent_partitions = 32")
ctx.sql("SET iceberg.max_concurrent_writers = 10")
ctx.sql("SET iceberg.buffer_size = 4")
ctx.sql("SET iceberg.parallel_manifest_reads = true")
```

### Iceberg Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `iceberg.max_concurrent_files` | int | 4 | Max data files to read in parallel |
| `iceberg.max_concurrent_partitions` | int | 8 | Max partitions to write in parallel |
| `iceberg.max_concurrent_writers` | int | 10 | Max concurrent write operations (INSERTs) |
| `iceberg.buffer_size` | int | 2 | Record batches buffered per stream |
| `iceberg.parallel_manifest_reads` | bool | true | Enable parallel manifest file reading |

### Performance Presets

#### High Throughput
For fast networks and high-core machines:

```sql
SET iceberg.max_concurrent_files = 16;
SET iceberg.max_concurrent_partitions = 32;
SET iceberg.max_concurrent_writers = 50;
SET iceberg.buffer_size = 4;
SET iceberg.parallel_manifest_reads = true;
```

#### Low Memory
For constrained environments:

```sql
SET iceberg.max_concurrent_files = 2;
SET iceberg.max_concurrent_partitions = 4;
SET iceberg.max_concurrent_writers = 5;
SET iceberg.buffer_size = 1;
SET iceberg.parallel_manifest_reads = false;
```

#### Sequential (Debugging)
For strict ordering or profiling:

```sql
SET iceberg.max_concurrent_files = 1;
SET iceberg.max_concurrent_partitions = 1;
SET iceberg.max_concurrent_writers = 1;
SET iceberg.buffer_size = 1;
SET iceberg.parallel_manifest_reads = false;
```

### Performance Guidelines

**Read Performance:**
- `max_concurrent_files` directly controls read parallelism
- Higher values = more parallel file reads = faster scans
- Benchmark shows ~8x speedup with `files=16` vs `files=1`

**Write Performance:**
- `max_concurrent_writers` controls concurrent INSERT operations
- **Important:** Single writer (writers=1) often achieves highest throughput due to Iceberg commit contention
- Benchmark results:
  - 1 writer: ~27,000 rows/sec
  - 10 writers: ~7,300 rows/sec
  - 50 writers: ~1,500 rows/sec
- Use fewer concurrent writers for maximum throughput; use more for latency distribution

**Memory Impact:**
- Higher concurrency = more memory usage
- Each concurrent file read buffers batches in memory
- For a 20GB table scan with default settings: ~100-200 MB memory (not 20GB)

## SQL SET Commands Reference

All configuration options can be set at runtime using SQL SET commands. This provides a convenient way to tune settings without restarting your session.

### AWS Configuration (SET aws.*)

```sql
-- Region and credentials
SET aws.region = 'us-east-1';
SET aws.access_key_id = 'AKIA...';
SET aws.secret_access_key = '...';
SET aws.session_token = '...';

-- Role assumption
SET aws.role_arn = 'arn:aws:iam::123456789012:role/MyRole';
SET aws.role_session_name = 'pathsdata-session';
SET aws.external_id = 'my-external-id';

-- Profile and endpoint
SET aws.profile_name = 'my-profile';
SET aws.endpoint = 'http://localhost:4566';

-- S3 Connection Pool Settings
SET aws.s3_pool_max_idle_per_host = 100;
SET aws.s3_pool_idle_timeout_secs = 90;
SET aws.s3_connect_timeout_secs = 5;
SET aws.s3_request_timeout_secs = 300;
SET aws.s3_http2_keep_alive_interval_secs = 10;
SET aws.s3_http2_keep_alive_timeout_secs = 30;
SET aws.s3_http2_keep_alive_while_idle = true;
```

#### AWS SET Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `aws.region` | string | - | AWS region (e.g., "us-east-1") |
| `aws.access_key_id` | string | - | AWS access key ID |
| `aws.secret_access_key` | string | - | AWS secret access key |
| `aws.session_token` | string | - | Session token for temporary credentials |
| `aws.role_arn` | string | - | IAM role ARN for role assumption |
| `aws.role_session_name` | string | - | Session name when assuming role |
| `aws.external_id` | string | - | External ID for cross-account access |
| `aws.profile_name` | string | - | AWS profile from ~/.aws/credentials |
| `aws.endpoint` | string | - | Custom AWS endpoint URL |
| `aws.s3_pool_max_idle_per_host` | int | 100 | Max idle connections per S3 host |
| `aws.s3_pool_idle_timeout_secs` | int | 90 | Idle connection timeout (seconds) |
| `aws.s3_connect_timeout_secs` | int | 5 | Connection timeout (seconds) |
| `aws.s3_request_timeout_secs` | int | 300 | Request timeout (seconds) |
| `aws.s3_http2_keep_alive_interval_secs` | int | 10 | HTTP/2 keep-alive ping interval |
| `aws.s3_http2_keep_alive_timeout_secs` | int | 30 | HTTP/2 keep-alive timeout |
| `aws.s3_http2_keep_alive_while_idle` | bool | true | Enable keep-alive for idle connections |

### Iceberg Configuration (SET iceberg.*)

```sql
-- Read parallelism
SET iceberg.max_concurrent_files = 16;
SET iceberg.parallel_manifest_reads = true;

-- Write parallelism
SET iceberg.max_concurrent_partitions = 32;
SET iceberg.max_concurrent_writers = 10;

-- Buffering
SET iceberg.buffer_size = 4;
```

#### Iceberg SET Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `iceberg.max_concurrent_files` | int | 4 | Max data files to read in parallel |
| `iceberg.max_concurrent_partitions` | int | 8 | Max partitions to write in parallel |
| `iceberg.max_concurrent_writers` | int | 10 | Max concurrent write operations |
| `iceberg.buffer_size` | int | 2 | Record batches buffered per stream |
| `iceberg.parallel_manifest_reads` | bool | true | Enable parallel manifest reading |

### DataFusion Execution Configuration (SET datafusion.*)

```sql
-- Parallelism
SET datafusion.execution.target_partitions = 8;
SET datafusion.execution.batch_size = 8192;

-- Memory
SET datafusion.execution.memory_limit = '4GB';
SET datafusion.execution.sort_spill_reservation_bytes = 10485760;

-- Parquet optimizations
SET datafusion.execution.parquet.pushdown_filters = true;
SET datafusion.execution.parquet.reorder_filters = true;
SET datafusion.execution.parquet.enable_page_index = true;
SET datafusion.execution.parquet.pruning = true;
SET datafusion.execution.parquet.bloom_filter_on_read = true;
```

#### DataFusion SET Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `datafusion.execution.target_partitions` | int | CPU cores | Query parallelism level |
| `datafusion.execution.batch_size` | int | 8192 | Rows per batch |
| `datafusion.execution.memory_limit` | string | - | Memory limit (e.g., "4GB") |
| `datafusion.execution.coalesce_batches` | bool | true | Combine small batches |
| `datafusion.execution.collect_statistics` | bool | true | Collect query statistics |
| `datafusion.execution.parquet.pushdown_filters` | bool | true | Push filters to Parquet reader |
| `datafusion.execution.parquet.reorder_filters` | bool | true | Optimize filter order |
| `datafusion.execution.parquet.enable_page_index` | bool | true | Use page-level statistics |
| `datafusion.execution.parquet.pruning` | bool | true | Enable row group pruning |
| `datafusion.execution.parquet.bloom_filter_on_read` | bool | true | Use bloom filters |

### Viewing Current Settings

```sql
-- Show all settings
SHOW ALL;

-- Show specific setting
SHOW iceberg.max_concurrent_files;
SHOW aws.region;
SHOW datafusion.execution.target_partitions;
```

## Environment Variable Reference

### AWS Variables

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key ID |
| `AWS_SECRET_ACCESS_KEY` | Secret access key |
| `AWS_SESSION_TOKEN` | Session token |
| `AWS_REGION` | Default region |
| `AWS_DEFAULT_REGION` | Fallback region |
| `AWS_PROFILE` | Default profile name |
| `AWS_CONFIG_FILE` | Config file path |
| `AWS_SHARED_CREDENTIALS_FILE` | Credentials file path |
| `AWS_ROLE_ARN` | Role ARN for web identity |
| `AWS_WEB_IDENTITY_TOKEN_FILE` | Token file for web identity |

## Example Configurations

### Development (LocalStack)

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.access_key_id": "test",
    "aws.secret_access_key": "test",
    "aws.endpoint": "http://localhost:4566"
})

ctx.register_iceberg("local", {
    "type": "glue",
    "glue.endpoint": "http://localhost:4566",
    "s3.endpoint": "http://localhost:4566"
})
```

### Production (AWS with IAM Role)

```python
# On EC2/ECS/Lambda - credentials from instance/task role
ctx = SessionContext({
    "aws.region": "us-east-1"
})

ctx.register_iceberg("warehouse", {
    "type": "glue"
})
```

### Multi-Region Setup

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "production"
})

# East coast catalog
ctx.register_iceberg("east", {
    "type": "glue",
    "glue.region": "us-east-1"
})

# West coast catalog
ctx.register_iceberg("west", {
    "type": "glue",
    "glue.region": "us-west-2"
})

# Query across regions
df = ctx.sql("""
    SELECT * FROM east.db.users
    UNION ALL
    SELECT * FROM west.db.users
""")
```

### Cross-Account Access

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.role_arn": "arn:aws:iam::OTHER_ACCOUNT:role/CrossAccountRole",
    "aws.role_session_name": "pathsdata-cross-account"
})

ctx.register_iceberg("other_account", {
    "type": "glue"
})
```

## Next Steps

- [Getting Started](../../getting-started/index.md) - Quick start guide
- [Python API](../python/index.md) - Python bindings reference
- [SQL Reference](../sql/index.md) - SQL syntax
