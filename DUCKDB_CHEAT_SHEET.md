# DuckDB Cheat Sheet: SQL & Python Reference Guide

A comprehensive, production-oriented reference guide for querying and manipulating **DuckDB** using both **DuckDB SQL Dialect** and the **Python API**. Designed for analytical engineering, data pipelines, and local data warehouse workflows.

---

## 📌 Table of Contents
1. [DuckDB SQL Syntax](#1-duckdb-sql-syntax)
   - [Friendly SQL Shortcuts](#a-friendly-sql-shortcuts)
   - [File & Format Querying](#b-file--format-querying)
   - [Aggregations & Grouping](#c-aggregations--grouping)
   - [Window Functions & QUALIFY](#d-window-functions--qualify)
   - [Common Table Expressions (CTEs)](#e-common-table-expressions-ctes)
   - [Nested Data (Lists & Structs)](#f-nested-data-lists--structs)
   - [Database Inspection](#g-database-inspection)
2. [DuckDB Python API Reference](#2-duckdb-python-api-reference)
   - [Database Connections](#a-database-connections)
   - [Executing Queries & Fetching Results](#b-executing-queries--fetching-results)
   - [DataFrame Interoperability (Pandas, Polars, Arrow)](#c-dataframe-interoperability-pandas-polars-arrow)
   - [Registering In-Memory Objects](#d-registering-in-memory-objects)
   - [Exporting & Persisting Data](#e-exporting--persisting-data)
3. [Best Practices & Performance Tips](#3-best-practices--performance-tips)

---

## 1. DuckDB SQL Syntax

### A. Friendly SQL Shortcuts
DuckDB provides powerful SQL shortcuts that reduce repetitive code.

```sql
-- 1. Select all except specific columns
SELECT * EXCLUDE (customer_id, internal_status) 
FROM raw_orders;

-- 2. Select all and replace/modify specific columns
SELECT * REPLACE (
    LOWER(customer_city) AS customer_city,
    UPPER(customer_state) AS customer_state
) 
FROM raw_customers;

-- 3. Omit SELECT clause entirely
FROM raw_orders 
WHERE order_status = 'delivered';

-- 4. Select columns using Regex / Glob pattern
SELECT COLUMNS('order_.*') 
FROM raw_orders;
```

---

### B. File & Format Querying
Query files directly from disk without creating tables first.

```sql
-- Direct CSV Querying
SELECT * FROM 'seeds/raw_orders.csv' LIMIT 10;

-- Direct Parquet Querying
SELECT * FROM 'data/orders.parquet' WHERE order_status = 'shipped';

-- Read multiple files with wildcards
SELECT * FROM 'data/orders_*.parquet';

-- Read JSON files directly
SELECT * FROM read_json_auto('data/payload.json');
```

---

### C. Aggregations & Grouping

```sql
SELECT 
    customer_state,
    COUNT(*) AS total_customers,
    -- Conditional aggregation using FILTER
    COUNT(*) FILTER (WHERE customer_city = 'sao paulo') AS sao_paulo_count,
    -- Aggregate values into a dynamic array
    LIST(DISTINCT customer_city) AS cities
FROM raw_customers
GROUP BY customer_state
HAVING COUNT(*) > 100
ORDER BY total_customers DESC;
```

---

### D. Window Functions & QUALIFY
Use `QUALIFY` to filter window function outputs without nested subqueries or CTEs.

```sql
-- Get the most recent order per customer
SELECT 
    order_id,
    customer_id,
    order_purchase_timestamp
FROM raw_orders
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id 
    ORDER BY order_purchase_timestamp DESC
) = 1;
```

---

### E. Common Table Expressions (CTEs)

```sql
WITH order_aggregates AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders
    FROM raw_orders
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.customer_city,
    a.total_orders
FROM raw_customers c
JOIN order_aggregates a ON c.customer_id = a.customer_id
WHERE a.total_orders > 3;
```

---

### F. Nested Data (Lists & Structs)

```sql
-- Unnest list array into separate rows
SELECT UNNEST([10, 20, 30]) AS score;

-- Create Structs (Key-Value)
SELECT {'order_id': '123', 'status': 'shipped'} AS order_details;

-- Lambda transformations over lists
SELECT list_transform([1, 2, 3, 4], lambda x: x * 2) AS doubled_list;
```

---

### G. Database Inspection

```sql
-- List all tables in current database
SHOW TABLES;

-- Inspect column definitions and data types
DESCRIBE raw_orders;

-- Generate column summary statistics
SUMMARIZE raw_orders;
```

---

## 2. DuckDB Python API Reference

### A. Database Connections

```python
import duckdb

# Persistent connection to a local database file
con = duckdb.connect('dev.duckdb')

# In-memory database (temporary/ephemeral)
mem_con = duckdb.connect()

# Read-only mode connection
ro_con = duckdb.connect('dev.duckdb', read_only=True)

# Always close connections when done in scripts
con.close()
```

---

### B. Executing Queries & Fetching Results

```python
import duckdb

con = duckdb.connect('dev.duckdb')

# 1. Terminal ASCII Output
con.sql("SELECT * FROM raw_orders LIMIT 5").show()

# 2. Fetch as Python Data Structures
df = con.sql("SELECT * FROM raw_orders").df()            # Pandas DataFrame
pl_df = con.sql("SELECT * FROM raw_orders").pl()         # Polars DataFrame
arrow = con.sql("SELECT * FROM raw_orders").arrow()     # PyArrow Table
tuples = con.sql("SELECT * FROM raw_orders").fetchall() # Python Tuples
```

---

### C. DataFrame Interoperability (Pandas, Polars, Arrow)
DuckDB can directly query Python in-memory DataFrames without copying data (Zero-Copy Execution).

```python
import duckdb
import pandas as pd

# Create a sample Pandas DataFrame
df_customers = pd.DataFrame({
    'customer_id': [1, 2, 3],
    'name': ['Alice', 'Bob', 'Charlie']
})

# Query Pandas DataFrame directly using DuckDB SQL
con = duckdb.connect()
con.sql("SELECT * FROM df_customers WHERE name LIKE 'A%'").show()
```

---

### D. Registering In-Memory Objects

```python
import duckdb

con = duckdb.connect('dev.duckdb')

# Register a DataFrame as a virtual SQL table inside connection
con.register('virtual_customers', df_customers)

# Query it as a standard table
con.sql("SELECT * FROM virtual_customers").show()

# Unregister when done
con.unregister('virtual_customers')
```

---

### E. Exporting & Persisting Data

```python
import duckdb

con = duckdb.connect('dev.duckdb')

# Export table or query to CSV
con.sql("COPY raw_orders TO 'output_orders.csv' (HEADER, DELIMITER ',')")

# Export table or query to compressed Parquet
con.sql("COPY raw_orders TO 'output_orders.parquet' (FORMAT PARQUET, COMPRESSION SNAPPY)")

# Export entire database as SQL dump scripts
con.sql("EXPORT DATABASE 'backup_directory'")
```

---

## 3. Best Practices & Performance Tips
1. **Prefer Parquet for Large Storage:** Use Parquet format over CSV for faster reads and auto-compression.
2. **Leverage `QUALIFY`:** Avoid verbose CTEs when filtering window operations like `ROW_NUMBER()`.
3. **Zero-Copy Ingestion:** Query existing Pandas or Polars DataFrames directly via `duckdb.sql("SELECT ... FROM df")` to save memory.
4. **Use Threads for Multi-Core Work:** Enable parallelism in Python scripts:
   ```python
   con.sql("SET threads TO 4;")
   ```
