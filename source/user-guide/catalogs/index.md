# Catalog Configuration Reference

This guide provides detailed configuration for each supported Iceberg catalog type.

## AWS Glue Catalog

AWS Glue Data Catalog is the most common choice for AWS-based data lakes.

### Required Configuration

| Option | Description |
|--------|-------------|
| `type` | Must be `"glue"` |

### Optional Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `glue.region` | string | From session | AWS region for Glue API |
| `glue.access-key-id` | string | From session/SDK | AWS access key for Glue |
| `glue.secret-access-key` | string | From session/SDK | AWS secret key for Glue |
| `glue.session-token` | string | - | Session token for temporary credentials |
| `glue.endpoint` | string | AWS default | Custom Glue endpoint URL |
| `glue.catalog-id` | string | Account ID | Glue catalog ID (for cross-account) |

### S3 Configuration (for data files)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `s3.region` | string | From session | S3 region for data files |
| `s3.access-key-id` | string | From Glue config | S3 access key |
| `s3.secret-access-key` | string | From Glue config | S3 secret key |
| `s3.endpoint` | string | AWS default | Custom S3 endpoint |

### Examples

#### Basic Usage (IAM Role)

```python
from pathsdata_test import SessionContext

# On EC2/ECS/Lambda with IAM role - no credentials needed
ctx = SessionContext({"aws.region": "us-east-1"})

ctx.register_iceberg("warehouse", {
    "type": "glue"
})

# Query tables
df = ctx.sql("SELECT * FROM warehouse.my_database.my_table")
```

#### With AWS Profile

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "production"
})

ctx.register_iceberg("warehouse", {
    "type": "glue",
    "glue.region": "us-east-1"
})
```

#### With Explicit Credentials

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.access_key_id": "AKIAIOSFODNN7EXAMPLE",
    "aws.secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
})

ctx.register_iceberg("warehouse", {
    "type": "glue"
})
```

#### Cross-Account Access

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.role_arn": "arn:aws:iam::TARGET_ACCOUNT:role/GlueCrossAccountRole",
    "aws.role_session_name": "pathsdata-session"
})

ctx.register_iceberg("other_account", {
    "type": "glue",
    "glue.catalog-id": "TARGET_ACCOUNT_ID"
})
```

#### LocalStack Testing

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

---

## AWS S3 Tables Catalog

AWS S3 Tables provides fully managed Iceberg tables directly in S3.

### Required Configuration

| Option | Description |
|--------|-------------|
| `type` | Must be `"s3tables"` |
| `s3tables.table-bucket-arn` | ARN of the S3 Tables bucket |

### Optional Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `s3tables.region` | string | From ARN | AWS region |
| `s3tables.access-key-id` | string | From session | AWS access key |
| `s3tables.secret-access-key` | string | From session | AWS secret key |
| `s3tables.session-token` | string | - | Session token |
| `s3tables.endpoint` | string | AWS default | Custom endpoint |

### Examples

#### Basic Usage

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"
})

ctx.register_iceberg("s3tables", {
    "type": "s3tables",
    "s3tables.table-bucket-arn": "arn:aws:s3tables:us-east-1:123456789012:bucket/my-table-bucket",
    "s3tables.region": "us-east-1"
})

# List namespaces
df = ctx.sql("SELECT * FROM s3tables.information_schema.schemata")
```

#### With Explicit Credentials

```python
ctx.register_iceberg("s3tables", {
    "type": "s3tables",
    "s3tables.table-bucket-arn": "arn:aws:s3tables:us-east-1:123456789012:bucket/my-bucket",
    "s3tables.region": "us-east-1",
    "s3tables.access-key-id": "AKIAIOSFODNN7EXAMPLE",
    "s3tables.secret-access-key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
})
```

### S3 Tables ARN Format

```
arn:aws:s3tables:<region>:<account-id>:bucket/<bucket-name>
```

Example: `arn:aws:s3tables:us-east-1:123456789012:bucket/analytics-tables`

---

## REST Catalog

REST catalog connects to any Iceberg REST catalog server (Tabular, Nessie, Polaris, etc.).

### Required Configuration

| Option | Description |
|--------|-------------|
| `type` | Must be `"rest"` |
| `uri` | REST catalog base URL |

### Optional Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rest.token` | string | - | Bearer token for authentication |
| `rest.credential` | string | - | OAuth2 client credentials (`client_id:client_secret`) |
| `rest.scope` | string | - | OAuth2 scope |
| `rest.prefix` | string | - | Warehouse prefix/path |
| `rest.audience` | string | - | OAuth2 audience |
| `rest.resource` | string | - | OAuth2 resource |
| `rest.oauth2-server-uri` | string | - | OAuth2 token endpoint |

### S3 Configuration (for data files)

| Option | Type | Description |
|--------|------|-------------|
| `s3.region` | string | S3 region for data files |
| `s3.access-key-id` | string | S3 access key |
| `s3.secret-access-key` | string | S3 secret key |
| `s3.endpoint` | string | Custom S3 endpoint |

### Examples

#### Bearer Token Authentication

```python
ctx = SessionContext()

ctx.register_iceberg("tabular", {
    "type": "rest",
    "uri": "https://api.tabular.io/ws",
    "rest.token": "your-api-token",
    "rest.prefix": "my-warehouse"
})
```

#### OAuth2 Client Credentials

```python
ctx.register_iceberg("catalog", {
    "type": "rest",
    "uri": "https://catalog.example.com",
    "rest.credential": "client_id:client_secret",
    "rest.scope": "catalog",
    "rest.oauth2-server-uri": "https://auth.example.com/oauth/token"
})
```

#### Nessie Catalog

```python
ctx.register_iceberg("nessie", {
    "type": "rest",
    "uri": "https://nessie.example.com/api/v1",
    "rest.token": "your-token",

    # S3 config for data files
    "s3.region": "us-east-1",
    "s3.access-key-id": "...",
    "s3.secret-access-key": "..."
})
```

#### Polaris Catalog

```python
ctx.register_iceberg("polaris", {
    "type": "rest",
    "uri": "https://polaris.example.com/api/catalog",
    "rest.credential": "client_id:client_secret",
    "rest.scope": "PRINCIPAL_ROLE:ALL",
    "rest.prefix": "my_catalog"
})
```

---

## SQL Catalog

SQL catalog stores Iceberg metadata in a relational database (PostgreSQL, MySQL, SQLite).

### Required Configuration

| Option | Description |
|--------|-------------|
| `type` | Must be `"sql"` |
| `uri` | Database connection string |

### Optional Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `warehouse` | string | - | Default warehouse location for tables |
| `sql.table-name` | string | `iceberg_tables` | Metadata table name |
| `sql.schema-name` | string | - | Database schema for metadata |

### S3 Configuration (for data files)

| Option | Type | Description |
|--------|------|-------------|
| `s3.region` | string | S3 region |
| `s3.access-key-id` | string | S3 access key |
| `s3.secret-access-key` | string | S3 secret key |
| `s3.endpoint` | string | Custom S3 endpoint |

### Connection String Formats

| Database | Format |
|----------|--------|
| PostgreSQL | `postgresql://user:pass@host:5432/database` |
| MySQL | `mysql://user:pass@host:3306/database` |
| SQLite | `sqlite:///path/to/catalog.db` or `sqlite:///:memory:` |

### Examples

#### PostgreSQL

```python
ctx = SessionContext()

ctx.register_iceberg("sql_catalog", {
    "type": "sql",
    "uri": "postgresql://iceberg:password@localhost:5432/iceberg_catalog",
    "warehouse": "s3://my-bucket/warehouse/",

    # S3 for data files
    "s3.region": "us-east-1",
    "s3.access-key-id": "...",
    "s3.secret-access-key": "..."
})
```

#### MySQL

```python
ctx.register_iceberg("mysql_catalog", {
    "type": "sql",
    "uri": "mysql://iceberg:password@localhost:3306/iceberg_db",
    "warehouse": "s3://data-lake/iceberg/"
})
```

#### SQLite (Local Development)

```python
ctx.register_iceberg("dev", {
    "type": "sql",
    "uri": "sqlite:///./iceberg_catalog.db",
    "warehouse": "/tmp/iceberg-data/"
})
```

#### SQLite In-Memory (Testing)

```python
ctx.register_iceberg("test", {
    "type": "sql",
    "uri": "sqlite:///:memory:",
    "warehouse": "/tmp/test-data/"
})
```

---

## File Catalog

File catalog stores metadata directly on a filesystem (local or S3). Best for testing and simple deployments.

### Required Configuration

| Option | Description |
|--------|-------------|
| `type` | Must be `"file"` |
| `warehouse` | Base path for catalog metadata and data |

### S3 Configuration (if using S3 warehouse)

| Option | Type | Description |
|--------|------|-------------|
| `s3.region` | string | S3 region |
| `s3.access-key-id` | string | S3 access key |
| `s3.secret-access-key` | string | S3 secret key |
| `s3.endpoint` | string | Custom S3 endpoint |

### Examples

#### Local Filesystem

```python
ctx = SessionContext()

ctx.register_iceberg("local", {
    "type": "file",
    "warehouse": "/home/user/iceberg-warehouse"
})

# Create table
ctx.sql("""
    CREATE EXTERNAL TABLE local.db.test (
        id BIGINT,
        name STRING
    ) STORED AS ICEBERG
""").collect()
```

#### S3-Backed File Catalog

```python
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"
})

ctx.register_iceberg("s3_file", {
    "type": "file",
    "warehouse": "s3://my-bucket/iceberg-catalog/",
    "s3.region": "us-east-1"
})
```

#### MinIO (S3-Compatible)

```python
ctx.register_iceberg("minio", {
    "type": "file",
    "warehouse": "s3://iceberg/warehouse/",
    "s3.endpoint": "http://localhost:9000",
    "s3.access-key-id": "minioadmin",
    "s3.secret-access-key": "minioadmin",
    "s3.region": "us-east-1"
})
```

---

## LanceDB Catalog

LanceDB provides vector database capabilities with SQL querying.

### Required Configuration

| Option | Description |
|--------|-------------|
| `uri` | Path to LanceDB database |

### Examples

#### Local LanceDB

```python
ctx = SessionContext()

ctx.register_lancedb("vectors", {
    "uri": "/path/to/lancedb"
})

# Query vector table
df = ctx.sql("SELECT * FROM vectors.my_embeddings LIMIT 10")
```

#### S3-Backed LanceDB

```python
ctx = SessionContext({
    "aws.region": "us-east-1"
})

ctx.register_lancedb("vectors", {
    "uri": "s3://my-bucket/lancedb/",
    "s3.region": "us-east-1"
})
```

---

## Configuration Priority

When the same option is specified at multiple levels, this priority applies:

1. **Catalog-specific** (e.g., `glue.access-key-id`) - Highest priority
2. **Storage-specific** (e.g., `s3.access-key-id`)
3. **Session config** (e.g., `aws.access_key_id`)
4. **Environment variables** (`AWS_ACCESS_KEY_ID`)
5. **AWS SDK credential chain** - Lowest priority

### Example: Mixed Configuration

```python
# Session-level defaults
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"
})

# Catalog with overrides
ctx.register_iceberg("warehouse", {
    "type": "glue",
    "glue.region": "us-west-2",  # Override region for Glue API
    "s3.region": "us-west-2"     # Override region for S3 data
})
```

---

## Troubleshooting

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `No credentials found` | Missing AWS credentials | Set `aws.profile_name` or explicit credentials |
| `Access Denied` | Insufficient IAM permissions | Check IAM policy for Glue/S3 access |
| `Region mismatch` | S3 bucket in different region | Set `s3.region` to match bucket region |
| `Connection refused` | Wrong endpoint URL | Verify endpoint URL is correct |
| `Table not found` | Wrong database/table name | Check catalog.database.table path |

### Required IAM Permissions

#### Glue Catalog

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:GetTable",
                "glue:GetTables",
                "glue:CreateTable",
                "glue:UpdateTable",
                "glue:DeleteTable",
                "glue:CreateDatabase",
                "glue:DeleteDatabase"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket",
                "arn:aws:s3:::your-bucket/*"
            ]
        }
    ]
}
```

#### S3 Tables

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3tables:GetTable",
                "s3tables:ListTables",
                "s3tables:CreateTable",
                "s3tables:DeleteTable",
                "s3tables:GetNamespace",
                "s3tables:ListNamespaces",
                "s3tables:CreateNamespace"
            ],
            "Resource": "*"
        }
    ]
}
```

## Next Steps

- [Iceberg Guide](../iceberg/index.md) - Table operations
- [Configuration](../configuration/index.md) - Session configuration
- [Python API](../python/index.md) - Python examples
