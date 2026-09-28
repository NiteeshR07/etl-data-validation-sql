-- ETL Data Validation Project
-- Source: etl_testing.sqbpro
-- Database: SQLite
--
-- This file contains the SQL used to load target tables, inject test defects,
-- and validate source-to-target ETL results.

PRAGMA foreign_keys = ON;

/* ================================================================
   1. ETL LOAD / SOURCE-TO-TARGET COPY
   ================================================================ */

INSERT INTO target_customers
    (customer_id, customer_name, city, email)
SELECT
    customer_id,
    customer_name,
    city,
    email
FROM source_customers;

INSERT INTO target_products
    (product_id, product_name, category, price)
SELECT
    product_id,
    product_name,
    category,
    price
FROM source_products;

INSERT INTO target_orders
    (order_id, customer_id, product_id, quantity, order_date)
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    order_date
FROM source_orders;

/* ================================================================
   2. RECORD COUNT / COMPLETENESS VALIDATION
   ================================================================ */

SELECT
    (SELECT COUNT(*) FROM source_customers) AS source_customers,
    (SELECT COUNT(*) FROM target_customers) AS target_customers,
    (SELECT COUNT(*) FROM source_orders) AS source_orders,
    (SELECT COUNT(*) FROM target_orders) AS target_orders;

/* ================================================================
   3. COLUMN-LEVEL SOURCE-TO-TARGET VALIDATION
   ================================================================ */

-- Customer field comparison
SELECT
    s.customer_id,
    s.customer_name AS source_name,
    t.customer_name AS target_name,
    s.email AS source_email,
    t.email AS target_email
FROM source_customers s
JOIN target_customers t
    ON s.customer_id = t.customer_id
WHERE s.customer_name <> t.customer_name
   OR s.email <> t.email;

-- Order field comparison
SELECT
    s.order_id,
    s.customer_id AS source_customer,
    t.customer_id AS target_customer,
    s.product_id AS source_product,
    t.product_id AS target_product,
    s.quantity AS source_quantity,
    t.quantity AS target_quantity,
    s.order_date AS source_date,
    t.order_date AS target_date
FROM source_orders s
JOIN target_orders t
    ON s.order_id = t.order_id
WHERE s.customer_id <> t.customer_id
   OR s.product_id <> t.product_id
   OR s.quantity <> t.quantity
   OR s.order_date <> t.order_date;

/* ================================================================
   4. QUANTITY MISMATCH TEST
   ================================================================ */

-- Test defect injection
UPDATE target_orders
SET quantity = 5
WHERE order_id = 1004;

-- Detect quantity mismatch
SELECT
    s.order_id,
    s.quantity AS source_quantity,
    t.quantity AS target_quantity
FROM source_orders s
JOIN target_orders t
    ON s.order_id = t.order_id
WHERE s.quantity <> t.quantity;

-- Restore test data
UPDATE target_orders
SET quantity = 3
WHERE order_id = 1004;

-- Re-run mismatch validation
SELECT
    s.order_id,
    s.quantity AS source_quantity,
    t.quantity AS target_quantity
FROM source_orders s
JOIN target_orders t
    ON s.order_id = t.order_id
WHERE s.quantity <> t.quantity;

/* ================================================================
   5. DUPLICATE RECORD VALIDATION
   ================================================================ */

-- Create staging table for duplicate-record test
CREATE TABLE target_orders_staging (
    order_id INTEGER,
    customer_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    order_date TEXT
);

INSERT INTO target_orders_staging
SELECT *
FROM target_orders;

-- Inject duplicate order for testing
INSERT INTO target_orders_staging
    (order_id, customer_id, product_id, quantity, order_date)
VALUES
    (1005, 105, 505, 1, '2026-09-05');

-- Detect duplicate order IDs in staging
SELECT
    order_id,
    COUNT(*) AS occurrence_count
FROM target_orders_staging
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Duplicate check on final target table
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM target_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

/* ================================================================
   6. NULL / MISSING VALUE VALIDATION
   ================================================================ */

-- Test NULL injection
UPDATE target_customers
SET email = NULL
WHERE customer_id = 103;

-- Detect NULL customer emails
SELECT
    customer_id,
    customer_name,
    email
FROM target_customers
WHERE email IS NULL;

-- Compare source and target email values
SELECT
    s.customer_id,
    s.email AS source_email,
    t.email AS target_email
FROM source_customers s
JOIN target_customers t
    ON s.customer_id = t.customer_id
WHERE s.email <> t.email
   OR (s.email IS NULL AND t.email IS NOT NULL)
   OR (s.email IS NOT NULL AND t.email IS NULL);

-- Restore test data
UPDATE target_customers
SET email = 'amit@gmail.com'
WHERE customer_id = 103;

-- General NULL check for target orders
SELECT
    COUNT(*) AS null_count
FROM target_orders
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR product_id IS NULL
   OR quantity IS NULL
   OR order_date IS NULL;

/* ================================================================
   7. DERIVED AMOUNT / TRANSFORMATION VALIDATION
   ================================================================ */

-- Add source-side unit price used to calculate expected amount
ALTER TABLE source_orders
ADD COLUMN unit_price REAL;

-- Add target-side calculated amount
ALTER TABLE target_orders
ADD COLUMN total_amount REAL;

-- Populate source unit prices for the test dataset
UPDATE source_orders
SET unit_price =
    CASE order_id
        WHEN 1001 THEN 100
        WHEN 1002 THEN 200
        WHEN 1003 THEN 150
        WHEN 1004 THEN 300
        WHEN 1005 THEN 250
    END;

-- Populate expected target amounts
UPDATE target_orders
SET total_amount =
    quantity *
    CASE order_id
        WHEN 1001 THEN 100
        WHEN 1002 THEN 200
        WHEN 1003 THEN 150
        WHEN 1004 THEN 300
        WHEN 1005 THEN 250
    END;

-- Review calculated target amounts
SELECT
    order_id,
    quantity,
    total_amount
FROM target_orders
ORDER BY order_id;

-- Test amount defect injection
UPDATE target_orders
SET total_amount = 850
WHERE order_id = 1004;

-- Detect amount mismatch
SELECT
    order_id,
    quantity,
    total_amount AS actual_amount,
    quantity *
    CASE order_id
        WHEN 1001 THEN 100
        WHEN 1002 THEN 200
        WHEN 1003 THEN 150
        WHEN 1004 THEN 300
        WHEN 1005 THEN 250
    END AS expected_amount
FROM target_orders
WHERE total_amount !=
      quantity *
      CASE order_id
          WHEN 1001 THEN 100
          WHEN 1002 THEN 200
          WHEN 1003 THEN 150
          WHEN 1004 THEN 300
          WHEN 1005 THEN 250
      END;

-- Additional amount test value from the original project
UPDATE target_orders
SET total_amount = 900
WHERE order_id = 1004;

/* ================================================================
   8. REFERENTIAL INTEGRITY / ORPHAN RECORD VALIDATION
   ================================================================ */

SELECT
    t.order_id,
    t.customer_id
FROM target_orders t
LEFT JOIN target_customers c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/* ================================================================
   9. SCHEMA VALIDATION
   ================================================================ */

PRAGMA table_info(source_orders);
PRAGMA table_info(target_orders);

/* ================================================================
   10. SOURCE-TO-TARGET AMOUNT RECONCILIATION
   ================================================================ */

SELECT
    s.order_id,
    s.quantity,
    s.unit_price,
    t.total_amount AS target_amount,
    (s.quantity * s.unit_price) AS expected_amount
FROM source_orders s
JOIN target_orders t
    ON s.order_id = t.order_id
WHERE t.total_amount != (s.quantity * s.unit_price);

/* ================================================================
   11. DATA QUALITY SUMMARY
   ================================================================ */

SELECT
    (SELECT COUNT(*) FROM source_customers) AS source_customers,
    (SELECT COUNT(*) FROM target_customers) AS target_customers,
    (SELECT COUNT(*) FROM source_orders) AS source_orders,
    (SELECT COUNT(*) FROM target_orders) AS target_orders,
    (SELECT COUNT(*)
     FROM target_orders
     WHERE order_id IS NULL
        OR customer_id IS NULL
        OR product_id IS NULL
        OR quantity IS NULL
        OR order_date IS NULL) AS null_records,
    (SELECT COUNT(*)
     FROM (
         SELECT order_id
         FROM target_orders
         GROUP BY order_id
         HAVING COUNT(*) > 1
     )) AS duplicate_orders,
    (SELECT COUNT(*)
     FROM source_orders s
     JOIN target_orders t
       ON s.order_id = t.order_id
     WHERE t.total_amount != (s.quantity * s.unit_price)
    ) AS amount_mismatches;

/* ================================================================
   12. BASIC BUSINESS-RULE VALIDATION
   ================================================================ */

-- Quantity and amount should not be negative/zero for this dataset
SELECT *
FROM target_orders
WHERE quantity <= 0
   OR total_amount < 0;

/* ================================================================
   13. TOTAL AMOUNT RECONCILIATION
   ================================================================ */

SELECT
    (SELECT SUM(quantity * unit_price)
     FROM source_orders) AS source_total,
    (SELECT SUM(total_amount)
     FROM target_orders) AS target_total;

/* ================================================================
   END OF ETL VALIDATION QUERIES
   ================================================================ */
