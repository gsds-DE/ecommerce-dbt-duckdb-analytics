# E-Commerce Analytics Engine (dbt + DuckDB)

## 📌 Project Overview
This project builds an end-to-end, production-grade analytics pipeline using **dbt (data build tool)** and **DuckDB**. It models 100,000+ real-world e-commerce transactions from the **Olist Brazilian E-Commerce Dataset**.

The primary goal is to transform messy operational data into clean, business-ready dimensional models (Star Schema) while demonstrating modern analytical engineering best practices: **Medallion Architecture**, **Data Quality Testing**, **Jinja/Macros**, **dbt Seeds**, and **SCD Type 2 Snapshots**.

---

## 🎯 Project Goals & Business Objectives
1. **Customer Lifecycle Analysis:** Compute Customer Lifetime Value (CLTV), total order counts, and retention/recency metrics.
2. **Fulfillment & Logistics Performance:** Calculate order delivery lead times, estimated vs. actual delivery delay metrics, and seller shipping efficiency.
3. **Financial & Revenue Insights:** Aggregate revenue by payment method (credit card, boleto, voucher) and evaluate payment installment behavior.
4. **Data Governance & Quality Control:** Implement rigorous automated schema and data integrity tests (uniqueness, referential integrity, non-null constraints, and accepted values).

---

## 🏗 Architecture & Data Flow

```
┌────────────────────────┐
│  Raw Data (CSV Seeds)  │  (Olist E-Commerce Raw Files)
└───────────┬────────────┘
            │
            ▼  (dbt seed)
┌────────────────────────┐
│   Raw Landing Zone    │  (DuckDB: raw_customers, raw_orders, raw_payments, etc.)
└───────────┬────────────┘
            │
            ▼  (dbt run -- select stg_*)
┌────────────────────────┐
│     Staging Layer      │  (Data cleaning, type casting, column standardization)
└───────────┬────────────┘
            │
            ▼  (dbt snapshot)
┌────────────────────────┐
│     Snapshot Layer     │  (SCD Type 2 tracking for changing customer profiles/states)
└───────────┬────────────┘
            │
            ▼  (dbt run -- select int_*)
┌────────────────────────┐
│   Intermediate Layer   │  (Multi-table joins, payment pivoting via Jinja macros)
└───────────┬────────────┘
            │
            ▼  (dbt run -- select dim_* fct_*)
┌────────────────────────┐
│  Analytics Marts Layer │  (Dimensional Star Schema: fct_orders, dim_customers)
└───────────┬────────────┘
            │
            ▼  (dbt test)
┌────────────────────────┐
│  Data Quality & Tests  │  (Automated tests for primary keys, foreign keys, & ranges)
└────────────────────────┘
```

---

## 📂 Source Data
* **Dataset:** Olist Brazilian E-Commerce Public Dataset
* **Source:** [Kaggle - Olist Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
* **Core Tables Used:**
  * `olist_customers_dataset.csv` → Raw customer demographic data
  * `olist_orders_dataset.csv` → Order timestamps and fulfillment status
  * `olist_order_payments_dataset.csv` → Transaction payment channels and installment counts
  * `olist_order_items_dataset.csv` → Order line item details and pricing
  * `olist_products_dataset.csv` → Product categories and specifications

---

## 💻 Local Environment & Configuration Details

### 1. Tools & Frameworks
* **OS Environment:** Windows 11
* **Python Version:** 3.12+
* **Virtual Environment:** `.venv`
* **Data Warehouse Engine:** DuckDB (Embedded, Serverless)
* **Transformation Tool:** dbt-duckDB (`dbt-core` v1.12+, `dbt-duckdb` v1.11+)

### 2. Connection Profile (`~/.dbt/profiles.yml`)
```yaml
dbt_project_1:
  target: dev_duckdb
  outputs:
    dev_duckdb:
      type: duckdb
      path: 'dev.duckdb'
      schema: 'main'
      threads: 1
```

### 3. Project Configuration (`dbt_project.yml`)
```yaml
name: 'dbt_project_1'
version: '1.0.0'
profile: 'dbt_project_1'

model-paths: ["models"]
seed-paths: ["seeds"]
test-paths: ["tests"]
analysis-paths: ["analyses"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

models:
  dbt_project_1:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

---

## 🛠 Key dbt Features Demonstrated

1. **dbt Seeds:** Loading raw CSV lookup datasets directly into DuckDB tables (`dbt seed`).
2. **Medallion Architecture:** Clean separation between `staging`, `intermediate`, and `marts` models.
3. **DRY Code with Jinja & Macros:** Custom Jinja macro (`pivot_payments.sql`) to convert row-based payment types into dynamic aggregate columns without repetitive SQL.
4. **SCD Type 2 Snapshots:** Historical tracking on customer attributes over time using `dbt snapshot` (`timestamp` or `check` strategy).
5. **Data Quality Governance:**
   * Generic tests (`unique`, `not_null`, `relationships`, `accepted_values`).
   * Custom singular tests checking logical rules (e.g., `order_delivered_after_purchase`).
6. **Auto-Generated Documentation & Lineage:** Using `dbt docs generate` to maintain a visual Directed Acyclic Graph (DAG) and data dictionary.

---

## 🚀 How to Run This Project

```cmd
# 1. Activate Virtual Environment
.venv\Scripts\activate

# 2. Verify Database Connection
dbt debug

# 3. Load Raw CSV Data into DuckDB
dbt seed

# 4. Run Snapshots (SCD Type 2)
dbt snapshot

# 5. Build All SQL Models (Staging -> Intermediate -> Marts)
dbt run

# 6. Execute Data Quality Tests
dbt test

# 7. Generate and View Interactive Documentation & Lineage
dbt docs generate
dbt docs serve
```

## Essential DuckDB SQL Syntax Cheatsheet

-- List all tables in active database
SHOW TABLES;

-- Inspect column schema and data types
DESCRIBE raw_customers;

-- Query a CSV file directly without loading it first
SELECT * FROM 'seeds/raw_orders.csv' LIMIT 10;

-- Export query results directly to Parquet or CSV
COPY (SELECT * FROM raw_orders) TO 'output_orders.parquet' (FORMAT PARQUET);