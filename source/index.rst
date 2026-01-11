.. image:: _static/images/logo.png
  :alt: PATHSDATA Logo
  :width: 300

=========
PATHSDATA
=========

PATHSDATA is a high-performance query engine built on Apache DataFusion with native support for Apache Iceberg and LanceDB.

Features
--------

- **Apache Iceberg** - Full read/write support with ACID transactions
- **Multiple Catalogs** - AWS Glue, S3 Tables, REST, SQL, File
- **DML Operations** - INSERT, UPDATE, DELETE, MERGE INTO
- **Time Travel** - Query historical data snapshots
- **LanceDB Integration** - Vector database support
- **Python & Rust APIs** - Native bindings for both languages
- **High Performance** - Built on Apache Arrow and DataFusion

.. _toc.getting-started:
.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   getting-started/index

.. _toc.user-guide:
.. toctree::
   :maxdepth: 2
   :caption: User Guide

   user-guide/index
   user-guide/configuration/index
   user-guide/iceberg/index
   user-guide/catalogs/index
   user-guide/python/index
   user-guide/sql/index

.. _toc.library-guide:
.. toctree::
   :maxdepth: 2
   :caption: Library Guide

   library-user-guide/index

.. _toc.lancedb:
.. toctree::
   :maxdepth: 2
   :caption: LanceDB

   user-guide/lancedb/index

.. _toc.links:
.. toctree::
   :maxdepth: 1
   :caption: Links

   GitHub <https://github.com/pathsdata/query-rust>
