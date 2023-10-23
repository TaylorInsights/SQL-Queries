-- Question 1
SELECT COUNT(order_id) AS Shipped_After_Due
FROM orders
WHERE shipped_date > required_date;

-- Question 2
SELECT first_name
, last_name
, state
, phone
FROM customers
WHERE state = 'NY'
AND phone IS NOT NULL;

-- Question 3
SELECT DISTINCT s.staff_id
, s.first_name
, s.last_name
FROM staffs AS s
LEFT JOIN orders AS o
ON s.staff_id = o.staff_id
LEFT JOIN order_items AS oi 
ON o.order_id = oi.order_id
WHERE discount > 0.05;

-- Question 4
WITH CTE_TOTAL_PRODUCTS AS (
    SELECT c.category_name
    , COUNT(p.product_id) AS total_products
FROM categories AS c
LEFT JOIN products AS p ON c.category_id = p.category_id
GROUP BY c.category_name
), 
CTE_LOW_STOCK_PRODUCTS AS (
SELECT p.product_id
    , c.category_name
FROM stocks AS s
INNER JOIN products AS p ON s.product_id = p.product_id
INNER JOIN categories AS c ON c.category_id = p.category_id
WHERE s.quantity < 3
)
SELECT CTE_TOTAL_PRODUCTS.category_name
    , CTE_TOTAL_PRODUCTS.total_products
    , COUNT(CTE_LOW_STOCK_PRODUCTS.product_id) AS total_low_stock
FROM CTE_TOTAL_PRODUCTS
LEFT JOIN CTE_LOW_STOCK_PRODUCTS ON CTE_TOTAL_PRODUCTS.category_name = CTE_LOW_STOCK_PRODUCTS.category_name
GROUP BY CTE_TOTAL_PRODUCTS.category_name, CTE_TOTAL_PRODUCTS.total_products;

-- Question 5
SELECT COUNT (o.order_id) AS order_count
, c.first_name
, c.last_name
FROM customers AS c
LEFT JOIN orders AS o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id
, c.first_name
, c.last_name
ORDER BY order_count DESC;

-- Question 6
SELECT c.customer_id
    , COUNT(DISTINCT o.store_id) AS num_distinct_stores_ordered_from
FROM orders AS o
FULL OUTER JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT o.store_id) > 1;

-- Question 7
SELECT COUNT(o.order_id) AS orders_per_store
, COUNT(DISTINCT o.customer_id) AS unique_customers
, s.store_name
, s.city
, s.state
FROM stores AS s
LEFT JOIN orders AS o
ON o.store_id = s.store_id
GROUP BY s.store_name
, s.city
, s.state;

-- Question 8
WITH multiorder_customer AS (
SELECT o.customer_id
, COUNT(DISTINCT o.order_id) AS multiple_orders
FROM orders AS o
FULL OUTER JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY o.customer_id
HAVING COUNT(DISTINCT o.order_id) > 1)

, order_dates AS (
SELECT order_date
, customer_id
FROM orders
WHERE customer_id 
IN (SELECT customer_id
FROM multiorder_customer)
)

, days_between_orders AS (
SELECT customer_id
, order_date
, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
, COALESCE(
DATEDIFF(day, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), order_date)
, 0
) AS days_between_orders
FROM order_dates
)

SELECT customer_id
, MIN(days_between_orders) AS min_days_between_orders
, MAX(days_between_orders) AS max_days_between_orders
, AVG(days_between_orders) AS avg_days_between_orders
FROM days_between_orders
GROUP BY customer_id;

-- Question 9
SELECT name
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID('orders') AND OBJECT_NAME(referenced_object_id) = 'customers';

ALTER TABLE orders
DROP CONSTRAINT FK__orders__customer__47DBAE45;

DROP TABLE customers;
