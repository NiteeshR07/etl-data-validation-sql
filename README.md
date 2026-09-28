# ETL Data Validation Project

## Overview

This project demonstrates SQL-based validation of data between source
and target tables in an ETL pipeline.

The project validates data completeness, accuracy, consistency,
uniqueness, and reconciliation between source and target datasets.

## Tools & Technologies

- SQLite
- SQL
- DB Browser for SQLite
- Git & GitHub

## Database Structure

### Source Tables
- source_customers
- source_products
- source_orders

### Target Tables
- target_customers
- target_products
- target_orders
- target_orders_staging

## Validation Performed

### 1. Record Count Validation
Compared the number of records between source and target tables.

### 2. NULL Validation
Checked target data for unexpected NULL values.

### 3. Duplicate Validation
Checked for duplicate order IDs in the target dataset.

### 4. Source-to-Target Validation
Compared customer IDs, product IDs, quantities and order dates
between source and target data.

### 5. Amount Reconciliation
Validated target order amounts against:

quantity × unit_price

### 6. Total Amount Reconciliation
Compared the total source transaction value with the total target
transaction value.

## Validation Results

| Validation | Result |
|---|---|
| Customer count | PASS |
| Order count | PASS |
| NULL validation | PASS |
| Duplicate validation | PASS |
| Amount validation | PASS |
| Total amount reconciliation | PASS |

## Files

- `etl_testing.db` - SQLite database containing source and target tables
- `validation_queries.sql` - SQL queries used for ETL validation

## Key SQL Concepts

- SELECT
- WHERE
- JOIN
- GROUP BY
- HAVING
- CASE
- COUNT
- SUM
- Subqueries
- Data reconciliation
- Source-to-target comparison
