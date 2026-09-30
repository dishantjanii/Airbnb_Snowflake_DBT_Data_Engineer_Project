# 🏠 Airbnb End-to-End Data Engineering Project

<div align="center">

![dbt](https://img.shields.io/badge/dbt-orange?style=for-the-badge&logo=dbt&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
![AWS S3](https://img.shields.io/badge/AWS_S3-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)

**A production-grade, end-to-end data engineering pipeline built with dbt + Snowflake + AWS**

*Implements a Medallion Architecture with incremental loading, SCD Type 2 snapshots, and analytics-ready gold layer models.*

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#%EF%B8%8F-architecture)
- [Data Model](#-data-model)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Usage](#-usage)
- [Key Features](#-key-features)
- [Data Quality](#-data-quality)
- [Security & Best Practices](#-security--best-practices)
- [Troubleshooting](#-troubleshooting)


---

## 🔭 Overview

This project implements a **complete end-to-end data engineering pipeline** for Airbnb data using modern cloud technologies. It demonstrates industry best practices in:

- ☁️ **Cloud data warehousing** with Snowflake
- 🔄 **Incremental data loading** to handle large-scale datasets efficiently
- 🏗️ **Medallion architecture** (Bronze → Silver → Gold)
- 📸 **Slowly Changing Dimensions (SCD Type 2)** with dbt Snapshots
- 🧩 **Reusable Jinja macros** for business logic
- 🧪 **Data quality testing** at every layer

The pipeline processes Airbnb **listings**, **bookings**, and **hosts** data from raw CSV files → AWS S3 → Snowflake staging → through all three medallion layers → analytics-ready gold tables.

---

## 🏗️ Architecture

### Data Flow

```
┌─────────────┐     ┌──────────┐     ┌─────────────────────────────────────────────┐
│  Source CSV  │────▶│  AWS S3  │────▶│                Snowflake                    │
│   Files      │     │  Bucket  │     │                                             │
└─────────────┘     └──────────┘     │  ┌──────────┐  ┌────────┐  ┌────────────┐  │
                                      │  │ Staging  │─▶│ Bronze │─▶│   Silver   │  │
                                      │  │  Layer   │  │  Layer │  │   Layer    │  │
                                      │  └──────────┘  └────────┘  └─────┬──────┘  │
                                      │                                   │         │
                                      │                            ┌──────▼──────┐  │
                                      │                            │ Gold Layer  │  │
                                      │                            │ (Analytics) │  │
                                      │                            └─────────────┘  │
                                      └─────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology |
|-----------|-----------|
| ☁️ Cloud Data Warehouse | Snowflake |
| 🔧 Transformation Layer | dbt (Data Build Tool) |
| 📦 Cloud Storage | AWS S3 |
| 🐍 Language | Python |
| 🔁 Version Control | Git / GitHub |
| 📐 SQL Templating | Jinja2 |

---

## 📊 Data Model

### Medallion Architecture

```
AIRBNB Database
│
├── STAGING Schema       ← Raw source data loaded from S3
│   ├── BOOKINGS
│   ├── HOSTS
│   └── LISTINGS
│
├── BRONZE Schema        ← Incremental ingestion layer
│   ├── BRONZE_BOOKINGS
│   ├── BRONZE_HOSTS
│   └── BRONZE_LISTINGS
│
├── SILVER Schema        ← Cleaned & enriched layer
│   ├── SILVER_BOOKINGS
│   ├── SILVER_HOSTS
│   └── SILVER_LISTINGS
│
└── GOLD Schema          ← Analytics-ready layer
    ├── OBT              ← One Big Table (denormalized)
    ├── FACT             ← Fact table for dimensional model
    ├── DIM_BOOKINGS     ← SCD Type 2 snapshot
    ├── DIM_HOSTS        ← SCD Type 2 snapshot
    └── DIM_LISTINGS     ← SCD Type 2 snapshot
```

---

### 🥉 Bronze Layer — Raw Ingestion

Incremental models that pull data from staging with minimal transformation. Only new rows (based on `CREATED_AT`) are loaded on each run.

| Model | Description | Materialization |
|-------|-------------|-----------------|
| `bronze_bookings` | Raw booking transactions | Incremental |
| `bronze_hosts` | Raw host records | Incremental |
| `bronze_listings` | Raw property listings | Incremental |

---

### 🥈 Silver Layer — Cleaned & Enriched

Business logic applied: data cleaning, type casting, derived columns, and string transformations.

| Model | Description | Key Transformations |
|-------|-------------|---------------------|
| `silver_bookings` | Validated bookings with computed total | `multiply()` macro for `TOTAL_AMOUNT` |
| `silver_hosts` | Host profiles with quality ratings | `REPLACE()` for name formatting, `CASE` for `RESPONSE_RATE_QUALITY` |
| `silver_listings` | Listings with price tier labels | `tag()` macro for `PRICE_PER_NIGHT_TAG` |

---

### 🥇 Gold Layer — Analytics-Ready

Denormalized, analytics-optimized datasets ready for BI tools and reporting.

| Model | Type | Description |
|-------|------|-------------|
| `obt` | Table | One Big Table — joins all silver models via dynamic Jinja loop |
| `fact` | Table | Fact table for star schema dimensional modeling |
| `bookings` | Ephemeral | Filtered booking fields from OBT |
| `hosts` | Ephemeral | Filtered host fields from OBT |
| `listings` | Ephemeral | Filtered listing fields from OBT |

---

### 📸 Snapshots (SCD Type 2)

Tracks historical changes using dbt's timestamp strategy. Automatically maintains `dbt_valid_from` and `dbt_valid_to` columns.

| Snapshot | Unique Key | Track Changes On |
|----------|------------|-----------------|
| `dim_bookings` | `BOOKING_ID` | `CREATED_AT` |
| `dim_hosts` | `HOST_ID` | `HOST_CREATED_AT` |
| `dim_listings` | `LISTING_ID` | `LISTINGS_CREATED_AT` |

**Example output:**

| HOST_ID | HOST_NAME | dbt_valid_from | dbt_valid_to |
|---------|-----------|----------------|--------------|
| 101 | John_Doe | 2023-01-01 | 2024-06-30 |
| 101 | John_Doe_Updated | 2024-07-01 | 9999-12-31 |

---

## 📁 Project Structure

```
AWS_DBT_Snowflake/
│
├── README.md                             # This file
├── pyproject.toml                        # Python project & dependency config
│
└── aws_dbt_snowflake_project/            # dbt project root
    │
    ├── dbt_project.yml                   # dbt project config (layers, schemas)
    ├── ExampleProfiles.yml               # ⚠️ Template — fill with your credentials
    │
    ├── models/
    │   ├── sources/
    │   │   └── sources.yml               # Snowflake source definitions
    │   │
    │   ├── bronze/                       # 🥉 Raw ingestion layer
    │   │   ├── bronze_bookings.sql
    │   │   ├── bronze_hosts.sql
    │   │   └── bronze_listings.sql
    │   │
    │   ├── silver/                       # 🥈 Cleaned & enriched layer
    │   │   ├── silver_bookings.sql
    │   │   ├── silver_hosts.sql
    │   │   └── silver_listings.sql
    │   │
    │   └── gold/                         # 🥇 Analytics layer
    │       ├── obt.sql                   # One Big Table (dynamic Jinja joins)
    │       ├── fact.sql                  # Fact table
    │       └── ephemeral/               # Intermediate models (not materialized)
    │           ├── bookings.sql
    │           ├── hosts.sql
    │           └── listings.sql
    │
    ├── macros/                           # Reusable SQL functions
    │   ├── generate_schema_name.sql      # Custom schema name override
    │   ├── multiply.sql                  # Arithmetic: round(x * y, precision)
    │   ├── tag.sql                       # Price tier: low / medium / high
    │   └── trimmer.sql                   # String: trim + uppercase
    │
    ├── snapshots/                        # SCD Type 2 definitions
    │   ├── dim_bookings.yml
    │   ├── dim_hosts.yml
    │   └── dim_listings.yml
    │
    ├── tests/                            # Custom data quality tests
    │   └── source_tests.sql
    │
    ├── analyses/                         # Ad-hoc exploratory queries
    │   ├── explore.sql
    │   ├── if_else.sql
    │   └── loop.sql
    │
    └── seeds/                            # Static reference data (CSV → table)
```

---

## 🚀 Getting Started

### Prerequisites

- ✅ [Snowflake Account](https://signup.snowflake.com/)
- ✅ [Python 3.12+](https://www.python.org/downloads/)
- ✅ [Git](https://git-scm.com/)
- ✅ AWS Account (for S3 data ingestion)

---

### 1. Clone the Repository

```bash
git clone https://github.com/dishantjanii/Airbnb_Snowflake_DBT_Data_Engineer_Project.git
cd Airbnb_Snowflake_DBT_Data_Engineer_Project
```

### 2. Create & Activate Virtual Environment

```bash
# Windows (PowerShell)
python -m venv .venv
.venv\Scripts\Activate.ps1

# macOS / Linux
python -m venv .venv
source .venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install dbt-core dbt-snowflake
# OR with pyproject.toml
pip install -e .
```

**Core dependencies:**

| Package | Version | Purpose |
|---------|---------|---------|
| `dbt-core` | ≥ 1.11.2 | dbt transformation engine |
| `dbt-snowflake` | ≥ 1.11.0 | Snowflake adapter |

### 4. Configure Your Snowflake Connection

Create `~/.dbt/profiles.yml` (your home directory — **not** inside the project):

```yaml
aws_dbt_snowflake_project:
  outputs:
    dev:
      type: snowflake
      account: <your-account-identifier>   # e.g. abc12345.us-east-1
      user: <your-username>
      password: <your-password>
      role: ACCOUNTADMIN
      database: AIRBNB
      schema: dbt_schema
      warehouse: COMPUTE_WH
      threads: 4
  target: dev
```

> ⚠️ **Never commit this file to Git.** It is already excluded via `.gitignore`.

### 5. Set Up Snowflake Objects

Run the DDL scripts in your Snowflake worksheet:

```sql
CREATE DATABASE IF NOT EXISTS AIRBNB;
CREATE SCHEMA IF NOT EXISTS AIRBNB.STAGING;
-- See DDL/ddl.sql for full table definitions
```

### 6. Load Source Data to Snowflake

Upload CSV files to Snowflake staging:

| CSV File | Snowflake Target |
|----------|-----------------|
| `bookings.csv` | `AIRBNB.STAGING.BOOKINGS` |
| `hosts.csv` | `AIRBNB.STAGING.HOSTS` |
| `listings.csv` | `AIRBNB.STAGING.LISTINGS` |

---

## 🔧 Usage

All commands run from inside `aws_dbt_snowflake_project/`:

```bash
cd aws_dbt_snowflake_project
```

| Command | Description |
|---------|-------------|
| `dbt debug` | Verify Snowflake connection |
| `dbt deps` | Install dbt packages |
| `dbt run` | Run all models |
| `dbt run --select bronze.*` | Run bronze layer only |
| `dbt run --select silver.*` | Run silver layer only |
| `dbt run --select gold.*` | Run gold layer only |
| `dbt run --select silver_hosts` | Run a single model |
| `dbt run --full-refresh` | Rebuild all models from scratch |
| `dbt test` | Run all data quality tests |
| `dbt snapshot` | Run SCD Type 2 snapshots |
| `dbt build` | Run models + tests + snapshots |
| `dbt docs generate && dbt docs serve` | Generate & view lineage docs |

---

## 🎯 Key Features

### 1. 🔄 Incremental Loading

Bronze and silver models load only **new rows** since the last run using `CREATED_AT` as a watermark:

```sql
{{ config(materialized = 'incremental') }}

SELECT * FROM {{ source('staging', 'bookings') }}
{% if is_incremental() %}
WHERE CREATED_AT > (SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') FROM {{ this }})
{% endif %}
```

### 2. 🧩 Custom Macros

Reusable business logic defined once, used across all models:

```sql
-- multiply.sql: compute booking total
{% macro multiply(x, y, precision) %}
    round({{ x }} * {{ y }}, {{ precision }})
{% endmacro %}

-- tag.sql: categorize price tier
{% macro tag(col) %}
    CASE
        WHEN {{ col }} < 100 THEN 'low'
        WHEN {{ col }} < 200 THEN 'medium'
        ELSE 'high'
    END
{% endmacro %}

-- trimmer.sql: clean string columns
{% macro trimmer(column_name, node) %}
    ({{ column_name | trim | upper }})
{% endmacro %}
```

**Used in models:**
```sql
{{ multiply('NIGHTS_BOOKED', 'BOOKING_AMOUNT', 2) }} AS TOTAL_AMOUNT
{{ tag('CAST(PRICE_PER_NIGHT AS INT)') }}            AS PRICE_PER_NIGHT_TAG
```

### 3. ⚡ Dynamic SQL with Jinja Loops

The `obt.sql` uses a Jinja dictionary loop to generate joins dynamically:

```sql
{% set configs = [
    { "table": "AIRBNB.SILVER.SILVER_BOOKINGS", "columns": "SILVER_bookings.*", "alias": "SILVER_bookings" },
    { "table": "AIRBNB.SILVER.SILVER_LISTINGS",  "columns": "SILVER_listings.HOST_ID, ...", "alias": "SILVER_listings",
      "join_condition": "SILVER_bookings.LISTING_ID = SILVER_listings.LISTING_ID" },
    { "table": "AIRBNB.SILVER.SILVER_HOSTS",     "columns": "SILVER_hosts.HOST_NAME, ...", "alias": "SILVER_hosts",
      "join_condition": "SILVER_listings.HOST_ID = SILVER_hosts.HOST_ID" }
] %}

SELECT
    {% for config in configs %}
        {{ config["columns"] }}{% if not loop.last %},{% endif %}
    {% endfor %}
FROM
    {% for config in configs %}
        {% if loop.first %}
            {{ config["table"] }} AS {{ config["alias"] }}
        {% else %}
            LEFT JOIN {{ config["table"] }} AS {{ config["alias"] }}
            ON {{ config["join_condition"] }}
        {% endif %}
    {% endfor %}
```

### 4. 📸 Slowly Changing Dimensions (SCD Type 2)

Snapshots automatically track historical changes with full audit history:

```yaml
snapshots:
  - name: dim_hosts
    relation: ref('hosts')
    config:
      schema: gold
      database: AIRBNB
      unique_key: HOST_ID
      strategy: timestamp
      updated_at: HOST_CREATED_AT
      dbt_valid_to_current: "to_date('9999-12-31')"
```

### 5. 🏗️ Schema Separation by Layer

dbt automatically routes models to the correct Snowflake schema:

```yaml
models:
  aws_dbt_snowflake_project:
    bronze:
      +materialized: table
      +schema: bronze        # → AIRBNB.BRONZE.*
    silver:
      +materialized: table
      +schema: silver        # → AIRBNB.SILVER.*
    gold:
      +materialized: table
      +schema: gold          # → AIRBNB.GOLD.*
      ephemeral:
        +materialized: ephemeral
```

### 6. 🌀 Ephemeral Models

Gold layer intermediate models exist only as CTEs — never physically materialized in Snowflake, saving storage and compute costs.

---

## 📈 Data Quality

### Custom Test

```sql
-- tests/source_tests.sql
-- Fails if any booking amount is below threshold
SELECT 1
FROM {{ source('staging', 'bookings') }}
WHERE BOOKING_AMOUNT < 200
```

### Testing Strategy

| Test Type | What It Checks |
|-----------|---------------|
| Source validation | Staging data is accessible and populated |
| Unique key | No duplicate `BOOKING_ID`, `HOST_ID`, `LISTING_ID` |
| Not null | Critical fields are never empty |
| Business rules | `BOOKING_AMOUNT >= 0`, valid `BOOKING_STATUS` values |

### Data Lineage

Run `dbt docs serve` to explore the interactive lineage graph:

```
STAGING.BOOKINGS ──▶ bronze_bookings ──▶ silver_bookings ──▶ obt ──▶ fact
STAGING.LISTINGS ──▶ bronze_listings ──▶ silver_listings ──▶ obt ──▶ dim_listings
STAGING.HOSTS    ──▶ bronze_hosts    ──▶ silver_hosts    ──▶ obt ──▶ dim_hosts
```

---

## 🔐 Security & Best Practices

### Credentials Management

- ✅ `profiles.yml` is in `.gitignore` — credentials are **never committed**
- ✅ Dedicated Snowflake `TRANSFORM` role with minimum required privileges
- ✅ Use environment variables in CI/CD pipelines
- ✅ Rotate Snowflake passwords regularly

### Performance Optimization

| Strategy | Where Applied |
|----------|--------------|
| Incremental models | Bronze + Silver — avoids full table scans |
| Ephemeral models | Gold intermediate — zero storage overhead |
| Watermark filtering | `WHERE CREATED_AT > MAX(CREATED_AT)` |
| Warehouse auto-suspend | Snowflake compute cost control |

---

## 🐛 Troubleshooting

### ❌ Connection Error
```
Database Error: Failed to connect to Snowflake
```
- Verify `~/.dbt/profiles.yml` credentials are correct
- Ensure your Snowflake warehouse is **Running** (not suspended)
- Check account identifier format: `abc12345.us-east-1`

### ❌ Compilation Error — Undefined Macro
```
Compilation Error: 'macro_name' is undefined
```
- Check for **typos in macro names** — e.g., `multipy` vs `multiply`
- Run `dbt deps` to install missing packages
- Use `{% ... %}` for logic, `{{ ... }}` for expressions

### ❌ Incremental Load Issues
```bash
# Force complete rebuild from scratch
dbt run --full-refresh
```

### ❌ Snapshot Not Tracking Changes
- Verify the `updated_at` column exists in the source model
- Ensure `unique_key` is truly unique in the source
- Check `dbt_valid_to_current` date is in the future


<div align="center">

**👤 Dishant Jani**

[![GitHub](https://img.shields.io/badge/GitHub-dishantjanii-181717?style=flat-square&logo=github)](https://github.com/dishantjanii)

*Technologies: Snowflake · dbt · AWS · Python · Jinja2 · SQL*

---

⭐ **If you found this project helpful, please give it a star!** ⭐

</div>
