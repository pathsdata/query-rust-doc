# Getting Started

PATHSDATA is a high-performance query engine built on Apache DataFusion with native support for Apache Iceberg and LanceDB. It provides both Python and Rust APIs for querying data lakes with full ACID transaction support.

## Installation

```bash
pip install pathsdata-test
```

## Quick Start

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

---

## Apache Iceberg Examples

### Connect to AWS Glue Catalog

```python
from pathsdata_test import SessionContext

# Configure AWS credentials
ctx = SessionContext({
    "aws.region": "us-east-1",
    "aws.profile_name": "default"
})

# Register Glue catalog
ctx.register_iceberg("warehouse", {
    "type": "glue"
})

# Query Iceberg tables
df = ctx.sql("SELECT * FROM warehouse.my_database.my_table LIMIT 10")
for batch in df.collect():
    print(batch.to_pandas())
```

### Create and Insert Data

```python
# Create a new Iceberg table
ctx.sql("""
    CREATE EXTERNAL TABLE warehouse.analytics.events (
        id BIGINT,
        event_type STRING,
        user_id BIGINT,
        created_at TIMESTAMP
    )
    STORED AS ICEBERG
    PARTITIONED BY (day(created_at))
    LOCATION 's3://my-bucket/events'
""")

# Insert data
ctx.sql("""
    INSERT INTO warehouse.analytics.events
    VALUES
        (1, 'click', 100, '2024-01-15 10:30:00'),
        (2, 'view', 101, '2024-01-15 11:00:00'),
        (3, 'purchase', 100, '2024-01-15 12:00:00')
""")
```

### Time Travel Queries

```python
# Query a specific snapshot
df = ctx.sql("""
    SELECT * FROM warehouse.analytics.events
    FOR VERSION AS OF 123456789
""")

# Query as of a timestamp
df = ctx.sql("""
    SELECT * FROM warehouse.analytics.events
    FOR TIMESTAMP AS OF '2024-01-15 10:00:00'
""")
```

### Update and Delete

```python
# Update records
ctx.sql("""
    UPDATE warehouse.analytics.events
    SET event_type = 'conversion'
    WHERE event_type = 'purchase'
""")

# Delete records
ctx.sql("""
    DELETE FROM warehouse.analytics.events
    WHERE created_at < '2024-01-01'
""")
```

### Merge Into (Upsert)

```python
ctx.sql("""
    MERGE INTO warehouse.analytics.events AS target
    USING staging.new_events AS source
    ON target.id = source.id
    WHEN MATCHED THEN UPDATE SET *
    WHEN NOT MATCHED THEN INSERT *
""")
```

### Using S3 Tables Catalog

```python
ctx.register_iceberg("s3tables", {
    "type": "s3tables",
    "s3tables.table-bucket-arn": "arn:aws:s3tables:us-east-1:123456789012:bucket/my-bucket",
    "s3tables.region": "us-east-1"
})

df = ctx.sql("SELECT * FROM s3tables.my_namespace.my_table")
```

---

## LanceDB Examples

### Connect to LanceDB (File Catalog)

```python
from pathsdata_test import SessionContext

ctx = SessionContext()

# Register file-based LanceDB catalog
ctx.register_lancedb("vectors", {
    "type": "file",
    "uri": "/path/to/lancedb"
})

# Or S3-backed
ctx.register_lancedb("vectors", {
    "type": "file",
    "uri": "s3://my-bucket/lancedb/",
    "s3.region": "us-east-1"
})
```

### Create Table with Vector Column

```python
# Create schema
ctx.sql("CREATE SCHEMA vectors.embeddings")

# Create table with vector embeddings
ctx.sql("""
    CREATE TABLE vectors.embeddings.documents (
        id BIGINT NOT NULL,
        title VARCHAR NOT NULL,
        content VARCHAR NOT NULL,
        embedding FLOAT[384] NOT NULL
    ) WITH (
        'vector_column' = 'embedding',
        'vector_dimension' = '384'
    )
""")
```

### Insert Data with Embeddings

```python
# Insert data from another source
ctx.sql("""
    INSERT INTO vectors.embeddings.documents
    SELECT id, title, content, embedding
    FROM staged_documents
""")
```

### Vector Similarity Search

```python
# L2 distance search (lower = more similar)
df = ctx.sql("""
    SELECT
        id,
        title,
        l2_distance(embedding, [0.1, 0.2, 0.3, ...]) as distance
    FROM vectors.embeddings.documents
    ORDER BY distance ASC
    LIMIT 10
""")

# Cosine similarity search (higher = more similar)
df = ctx.sql("""
    SELECT
        id,
        title,
        cosine_similarity(embedding, [0.1, 0.2, 0.3, ...]) as similarity
    FROM vectors.embeddings.documents
    ORDER BY similarity DESC
    LIMIT 10
""")
```

### pgvector-Style Operators

```python
# L2 distance with <-> operator
df = ctx.sql("""
    SELECT id, title, embedding <-> [0.1, 0.2, ...] as distance
    FROM vectors.embeddings.documents
    ORDER BY distance ASC
    LIMIT 10
""")

# Cosine distance with <=> operator
df = ctx.sql("""
    SELECT id, title, embedding <=> [0.1, 0.2, ...] as distance
    FROM vectors.embeddings.documents
    ORDER BY distance ASC
    LIMIT 10
""")
```

### Hybrid Search (Vector + Filters)

```python
# Combine vector search with SQL filters
df = ctx.sql("""
    SELECT
        id,
        title,
        embedding <-> [0.1, 0.2, ...] as distance
    FROM vectors.embeddings.documents
    WHERE category = 'technology' AND published = true
    ORDER BY distance ASC
    LIMIT 10
""")
```

### Full-Text Search

```python
# Boolean text match
df = ctx.sql("""
    SELECT id, title, content
    FROM vectors.embeddings.documents
    WHERE match_text(content, 'machine learning')
""")

# Full-text search with relevance scoring
df = ctx.sql("""
    SELECT
        id,
        title,
        match_text_score(content, 'machine learning') as score
    FROM vectors.embeddings.documents
    WHERE match_text(content, 'machine learning')
    ORDER BY score DESC
    LIMIT 10
""")
```

### Create Vector Index

```python
# Create IVF_PQ index for fast similarity search
ctx.sql("""
    CREATE INDEX idx_embedding
    ON vectors.embeddings.documents
    USING IVF_PQ (embedding)
    WITH (distance_type = 'COSINE', num_partitions = 256)
""")

# Show indexes
ctx.sql("SHOW INDEXES ON vectors.embeddings.documents")
```

### Using Glue Catalog with LanceDB

```python
ctx.register_lancedb("lance_glue", {
    "type": "glue",
    "glue.region": "us-east-1",
    "s3.region": "us-east-1"
})

# Create schema with warehouse path
ctx.sql("""
    CREATE SCHEMA lance_glue.vectors
    WITH ('warehouse_path' = 's3://my-bucket/lancedb/')
""")
```

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Apache Iceberg** | Full read/write support with ACID transactions |
| **LanceDB** | Vector similarity search and full-text search |
| **Multiple Catalogs** | Glue, S3 Tables, REST, SQL, File catalogs |
| **DML Operations** | INSERT, UPDATE, DELETE, MERGE INTO |
| **Time Travel** | Query historical snapshots |
| **Vector Search** | L2, Cosine, Dot Product with pgvector operators |
| **Hybrid Search** | Combine vector + SQL filters + full-text |
| **Python & Rust APIs** | Native bindings for both languages |

## Next Steps

- [Apache Iceberg Guide](../user-guide/iceberg/index.md) - Complete Iceberg documentation
- [LanceDB Guide](../user-guide/lancedb/index.md) - Vector database documentation
- [Configuration Reference](../user-guide/configuration/index.md) - AWS and performance tuning
- [Python API](../user-guide/python/index.md) - Python API reference
- [SQL Reference](../user-guide/sql/index.md) - SQL syntax and statements
