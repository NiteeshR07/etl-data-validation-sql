# ETL Data Validation - Test Cases

## Test Objective

Validate the completeness, consistency, uniqueness, and accuracy of data
between source and target tables in the ETL pipeline.

---

## Test Cases

| Test ID | Test Scenario | Validation Logic | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| TC001 | Customer record count validation | Compare source_customers and target_customers counts | Source and target counts should match | 5 = 5 | PASS |
| TC002 | Order record count validation | Compare source_orders and target_orders counts | Source and target counts should match | 5 = 5 | PASS |
| TC003 | NULL value validation | Check target records for unexpected NULL values | No unexpected NULL values | 0 NULL records | PASS |
| TC004 | Duplicate order validation | Group target orders by order_id and check COUNT > 1 | No duplicate order IDs | 0 duplicates | PASS |
| TC005 | Order amount validation | Compare target total_amount with quantity × unit_price | Amounts should match | No mismatches | PASS |
| TC006 | Source-to-target field validation | Compare customer_id, product_id, quantity and order_date | Corresponding source and target values should match | No mismatches identified | PASS |
| TC007 | Total transaction reconciliation | Compare SUM(quantity × unit_price) with SUM(total_amount) | Source and target totals should match | 1800 = 1800 | PASS |

---

## Validation Categories

### 1. Completeness

Ensures that records present in the source system are correctly
represented in the target system.

### 2. Accuracy

Validates calculated values such as:

`quantity × unit_price = total_amount`

### 3. Consistency

Compares corresponding fields between source and target tables.

### 4. Uniqueness

Checks that order IDs are not duplicated in the target dataset.

### 5. NULL Validation

Checks for unexpected NULL values in important target fields.

### 6. Reconciliation

Compares the overall transaction value between source and target data.

---

## Final Validation Summary

- Customer records: 5 source / 5 target
- Order records: 5 source / 5 target
- NULL records: 0
- Duplicate orders: 0
- Amount mismatches: 0
- Source transaction total: 1800
- Target transaction total: 1800

All validation checks executed for this dataset passed.
