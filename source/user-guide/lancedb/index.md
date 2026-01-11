# LanceDB

LanceDB is a vector database that provides high-performance similarity search and full-text search capabilities. PATHSDATA integrates LanceDB to enable vector search workloads alongside traditional SQL analytics.

## Features

- **Vector Similarity Search** - L2, Cosine, and Dot Product distance metrics
- **Full-Text Search** - BM25-based text search with relevance scoring
- **Hybrid Search** - Combine vector and text search in single queries
- **Multiple Catalogs** - File, S3, Memory, and AWS Glue catalog backends
- **Vector Indexes** - IVF_PQ, IVF_HNSW_SQ, IVF_HNSW_PQ, IVF_FLAT, FLAT
- **pgvector Compatibility** - Support for `<->`, `<=>`, `<#>` operators
- **SQL Interface** - Full DDL/DML support via standard SQL

## Supported Catalogs

| Catalog | Type | Use Case |
|---------|------|----------|
| File Catalog | `file` | Local development, single-machine deployments |
| S3 Catalog | `s3` | Enterprise S3-based data lakes, multi-tenant |
| Memory Catalog | `memory` | Testing, prototyping, ephemeral workloads |
| Glue Catalog | `glue` | AWS Glue ecosystem integration |

### File Catalog

Local filesystem or cloud storage via object_store:

```python
# Local filesystem
ctx.register_lancedb("vectors", {
    "type": "file",
    "uri": "/path/to/lancedb"
})

# S3-backed file catalog
ctx.register_lancedb("vectors", {
    "type": "file",
    "uri": "s3://my-bucket/lancedb/",
    "s3.region": "us-east-1"
})
```

### S3 Catalog

Enterprise S3-based metadata storage with separate data warehouse:

```python
ctx.register_lancedb("vectors", {
    "type": "s3",
    "bucket": "my-catalog-bucket",
    "prefix": "lancedb",  # Optional prefix in bucket

    # S3 credentials
    "s3.region": "us-east-1",
    "s3.access-key-id": "AKIA...",
    "s3.secret-access-key": "...",

    # Optional: custom endpoint for MinIO/LocalStack
    "s3.endpoint": "http://localhost:9000",
    "s3.path-style-access": "true",
    "s3.allow-http": "true"
})

# Create namespace with warehouse path (required for S3 catalog)
ctx.sql("""
    CREATE SCHEMA vectors.analytics
    WITH ('warehouse_path' = 's3://data-bucket/warehouse/')
""")
```

#### S3 Catalog Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `bucket` | string | **Yes** | S3 bucket for catalog metadata |
| `prefix` | string | No | Prefix path within bucket |
| `s3.region` | string | **Yes** | AWS region |
| `s3.access-key-id` | string | No | AWS access key (uses credential chain if not set) |
| `s3.secret-access-key` | string | No | AWS secret key |
| `s3.session-token` | string | No | Session token for temporary credentials |
| `s3.endpoint` | string | No | Custom S3 endpoint (MinIO, LocalStack, R2) |
| `s3.path-style-access` | bool | No | Use path-style URLs (required for MinIO) |
| `s3.allow-http` | bool | No | Allow non-HTTPS connections (dev only) |

### Memory Catalog

In-memory catalog for testing and ephemeral workloads:

```python
ctx.register_lancedb("test_vectors", {
    "type": "memory"
})

# All data is temporary and will be lost when session ends
```

### Glue Catalog

AWS Glue Data Catalog integration with S3 storage:

```python
# From environment credentials
ctx.register_lancedb("vectors", {
    "type": "glue"
})

# With explicit configuration
ctx.register_lancedb("vectors", {
    "type": "glue",
    "glue.region": "us-east-1",
    "s3.region": "us-east-1",

    # Optional: explicit credentials
    "glue.access-key-id": "AKIA...",
    "glue.secret-access-key": "...",

    # Optional: custom endpoint (LocalStack)
    "glue.endpoint": "http://localhost:4566"
})
```

#### Glue Catalog Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `glue.region` | string | No | AWS region (falls back to s3.region) |
| `glue.access-key-id` | string | No | Glue-specific access key |
| `glue.secret-access-key` | string | No | Glue-specific secret key |
| `glue.session-token` | string | No | Glue-specific session token |
| `glue.endpoint` | string | No | Custom Glue endpoint (LocalStack) |
| `s3.region` | string | **Yes** | S3 region for data storage |

## SQL Reference

### DDL Operations

#### CREATE SCHEMA

```sql
-- Basic schema creation
CREATE SCHEMA catalog.schema_name;

-- Schema with warehouse path (required for S3/Glue catalogs)
CREATE SCHEMA catalog.schema_name
WITH ('warehouse_path' = 's3://bucket/warehouse/');
```

#### DROP SCHEMA

```sql
DROP SCHEMA catalog.schema_name;
DROP SCHEMA IF EXISTS catalog.schema_name;
```

#### CREATE TABLE

```sql
-- Basic table
CREATE TABLE catalog.schema.table_name (
    id BIGINT NOT NULL,
    name VARCHAR NOT NULL,
    content VARCHAR NOT NULL
);

-- Table with vector column
CREATE TABLE catalog.schema.documents (
    id BIGINT NOT NULL,
    title VARCHAR NOT NULL,
    content VARCHAR NOT NULL,
    embedding FLOAT[384] NOT NULL
) WITH (
    'vector_column' = 'embedding',
    'vector_dimension' = '384'
);
```

#### DROP TABLE

```sql
DROP TABLE catalog.schema.table_name;
DROP TABLE IF EXISTS catalog.schema.table_name;
```

### Index Operations

#### CREATE INDEX

```sql
-- Create IVF_PQ index (recommended for large datasets)
CREATE INDEX idx_embedding ON catalog.schema.table_name
USING IVF_PQ (embedding);

-- Create with custom parameters
CREATE INDEX idx_embedding ON catalog.schema.table_name
USING IVF_PQ (embedding)
WITH (
    distance_type = 'COSINE',
    num_partitions = 256,
    num_sub_vectors = 96
);

-- Other index types
CREATE INDEX idx ON table USING IVF_FLAT (embedding);
CREATE INDEX idx ON table USING IVF_HNSW_SQ (embedding);
CREATE INDEX idx ON table USING IVF_HNSW_PQ (embedding);
CREATE INDEX idx ON table USING FLAT (embedding);

-- Create only if not exists
CREATE INDEX IF NOT EXISTS idx ON table USING IVF_PQ (embedding);
```

#### Index Types

| Index Type | Search Speed | Memory | Accuracy | Best For |
|------------|--------------|--------|----------|----------|
| `IVF_PQ` | Fast | Low | Good | Large datasets (>100K rows) |
| `IVF_HNSW_SQ` | Very Fast | Medium | Very Good | Balanced performance |
| `IVF_HNSW_PQ` | Very Fast | Low | Good | Large datasets, memory constrained |
| `IVF_FLAT` | Moderate | High | Excellent | High accuracy requirements |
| `FLAT` | Slow | High | Perfect | Small datasets (<10K rows) |

#### Index Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `distance_type` | `L2` | Distance metric: `L2`, `COSINE`, `DOT` |
| `num_partitions` | 256 | IVF partitions (more = better accuracy, slower build) |
| `num_sub_vectors` | 16 | PQ sub-vectors (more = better accuracy, more memory) |

#### DROP INDEX / SHOW INDEXES

```sql
DROP INDEX idx_embedding ON catalog.schema.table_name;
SHOW INDEXES ON catalog.schema.table_name;
```

### DML Operations

#### INSERT INTO

```sql
INSERT INTO catalog.schema.target_table
SELECT * FROM source_table;

INSERT INTO catalog.schema.documents (id, title, content, embedding)
SELECT id, title, content, embedding FROM temp_data;
```

#### SELECT Queries

```sql
-- Basic queries
SELECT id, name, price FROM products;
SELECT * FROM products WHERE price < 100 AND stock > 0;
SELECT name, price FROM products ORDER BY rating DESC LIMIT 10;

-- Aggregations
SELECT category_id, COUNT(*), AVG(price)
FROM products GROUP BY category_id;

-- JOINs
SELECT p.name, c.name as category
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id;

-- Window functions
SELECT name, ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC)
FROM products;
```

## Vector Search

### Distance Functions

```sql
-- L2 (Euclidean) distance - lower is more similar
SELECT id, name, l2_distance(embedding, [0.1, 0.2, 0.3, ...]) as distance
FROM products ORDER BY distance ASC LIMIT 10;

-- Cosine similarity - higher is more similar
SELECT id, name, cosine_similarity(embedding, [0.1, 0.2, 0.3, ...]) as similarity
FROM products ORDER BY similarity DESC LIMIT 10;

-- Dot product - higher is more similar
SELECT id, name, dot_product(embedding, [0.1, 0.2, 0.3, ...]) as score
FROM products ORDER BY score DESC LIMIT 10;
```

### pgvector-Style Operators

```sql
-- <-> operator: L2 distance
SELECT id, name, embedding <-> [0.1, 0.2, 0.3, ...] as distance
FROM products ORDER BY distance ASC LIMIT 10;

-- <=> operator: Cosine distance
SELECT id, name, embedding <=> [0.1, 0.2, 0.3, ...] as distance
FROM products ORDER BY distance ASC LIMIT 10;

-- <#> operator: Negative inner product
SELECT id, name, embedding <#> [0.1, 0.2, 0.3, ...] as neg_ip
FROM products ORDER BY neg_ip ASC LIMIT 10;
```

### Hybrid Search (Vector + Filters)

```sql
-- Pre-filtering: filter before vector search
SELECT id, name, embedding <-> [0.1, 0.2, ...] as distance
FROM products
WHERE category = 'Electronics' AND price < 500
ORDER BY distance ASC LIMIT 10;

-- Post-filtering: filter on distance threshold
SELECT id, name, embedding <-> [0.1, 0.2, ...] as distance
FROM products
WHERE embedding <-> [0.1, 0.2, ...] < 1.0
ORDER BY distance ASC LIMIT 10;

-- Multi-vector weighted search
SELECT id, name,
    0.3 * (title_embedding <-> query1) +
    0.7 * (content_embedding <-> query2) as combined_score
FROM documents ORDER BY combined_score ASC LIMIT 10;
```

## Full-Text Search

### Text Matching

```sql
-- Boolean text match
SELECT id, title, content
FROM articles
WHERE match_text(content, 'machine learning');

-- Text match with relevance score
SELECT id, title, match_text_score(content, 'machine learning') as score
FROM articles
WHERE match_text(content, 'machine learning')
ORDER BY score DESC;

-- BM25 score from FTS index
SELECT id, title, _fts_score as bm25_score
FROM articles
WHERE match_text(content, 'machine learning')
ORDER BY _fts_score DESC LIMIT 10;
```

### Hybrid Search (Vector + Full-Text)

```sql
-- Vector + FTS combined
SELECT id, title,
    embedding <-> [0.1, 0.2, ...] as vec_distance,
    match_text_score(content, 'programming') as text_score
FROM articles
WHERE match_text(content, 'programming')
ORDER BY vec_distance ASC LIMIT 10;
```

## Function Reference

### Vector Distance Functions

| Function | Description | Ordering |
|----------|-------------|----------|
| `l2_distance(vec1, vec2)` | Euclidean distance | ASC (lower = more similar) |
| `cosine_similarity(vec1, vec2)` | Cosine similarity | DESC (higher = more similar) |
| `cosine_distance(vec1, vec2)` | 1 - cosine_similarity | ASC (lower = more similar) |
| `dot_product(vec1, vec2)` | Inner product | DESC (higher = more similar) |
| `negative_inner_product(vec1, vec2)` | Negative dot product | ASC (lower = more similar) |

### Full-Text Search Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `match_text(column, 'query')` | Boolean text match | BOOLEAN |
| `match_text_score(column, 'query')` | TF-IDF relevance score | FLOAT |
| `_fts_score` | BM25 score from FTS index | FLOAT (virtual column) |

### pgvector Operators

| Operator | Equivalent Function | Description |
|----------|---------------------|-------------|
| `<->` | `l2_distance()` | L2 (Euclidean) distance |
| `<=>` | `cosine_distance()` | Cosine distance |
| `<#>` | `negative_inner_product()` | Negative inner product |

## Choosing a Catalog

| Scenario | Recommended | Reason |
|----------|-------------|--------|
| Local development | File Catalog | Simple setup, no AWS required |
| Unit tests | Memory Catalog | Fast, ephemeral, no disk I/O |
| AWS S3 data lake | S3 Catalog | Enterprise pattern, multi-tenant |
| AWS Glue ecosystem | Glue Catalog | Native Glue integration |
| MinIO/LocalStack | S3 Catalog + custom endpoint | S3-compatible storage |
