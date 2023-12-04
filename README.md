# SQL-Queries
## Question 1: How many orders were shipped after the due (required) date?
### I chose the COUNT function to count the occurences of 'order_id' where the shipped_date is greater than the 'required_date' in the 'orders' table. The result will be under ALIAS 'shipped_after_due'.
```sql 
SELECT COUNT(order_id) AS shipped_after_due
FROM orders
WHERE shipped_date > required_date;
```

## Question 2: Name all customers who live in New York and provided a phone number.
### I used the WHERE clause to filter the results to only included NY as the state and WHERE the phone number IS NOT NULL or empty.
```sql 
SELECT first_name
, last_name
, state
, phone 
FROM customers
WHERE state = 'NY'
AND phone IS NOT NULL;
```

## Question 3: List all staff member names (no duplicates) who had a discount greater than 5% (0.05)
### I used DISTINCT to ensure that only unique combinations of the 'staffs' table are returned. Using a LEFT JOIN to combine the 'staffs' table with the 'orders' table. WHERE the discount is greater the 0.05 (5%).
```sql
SELECT DISTINCT s.staff_id
, s.first_name
, s.last_name
FROM staffs AS s
LEFT JOIN orders AS o
ON s.staff_id = o.staff_id
LEFT JOIN order_items AS oi 
ON o.order_id = oi.order_id
WHERE discount > 0.05;
```

## Question 4: How many products from each product category need to be reordered (stock < 3)? Please provide the category name, number of total products in that category, and number of products that need to be reordered.
### In this example I use a Common Table Expression (CTE) to perform analysis on product categories and their stock quantities. The CTE was chosen to organize the SQL query into more manageable parts.
### 'CTE_TOTAL_PRODUCTS' calculates the total number of products within each category using a LEFT JOIN.
### 'CTE_LOW_STOCK_PRODUCTS' identifies products in categories with low stock (less than 3 items) using an INNER JOIN and COUNT.
### Final Query uses the two previous CTE's to perform final analysis. This query is joined by 'category_name'. It COUNTs the number of product with low stock within each category and uses GROUP BY to group them by category_name.
```sql
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
```

## Question 5: Rank each of the customers by number of orders. Make sure to list the customer name. 
### Using the COUNT function to count orders for each customer including those who don't have orders. GROUP BY groups the results to ensure that the count of orders is aggregated per customer. ORDER BY (DESC) lists the results in descending order, meaning the customer with the highest number of orders will appear first.
```sql
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
```

## Question 6: List all customers who ordered from multiple stores.
### Using COUNT and DISTINCT to calculate the number of different stores a customer has ordered from. I used a FULL OUTER JOIN to combine data from both tables ensuring that all customers and their orders are included in the results. Additionally, I used GROUP BY to aggregate the counts for each customer and HAVING to only include customer who have placed orders from more than one DISTINCT store.
```sql 
SELECT c.customer_id
    , COUNT(DISTINCT o.store_id) AS num_distinct_stores_ordered_from
FROM orders AS o
FULL OUTER JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT o.store_id) > 1;
```

## Question 7: Name all stores (with store name, city, and state), how many unique customers have ordered from each (including zeros), and total number of orders. 
### This query COUNTs the number of orders made and COUNT of DISTINCT customers for each store. It lists the store's name, city and state then uses a LEFT JOIN based on the store ID. Lastly, it uses GROUP BY to combine the results by store's name, city and state.
```sql
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
```
## Question 8: For customers with more than 1 order, calculate the minimum, maximum, and average number of dates between orders.
### In this example, the queries are used to analyze the time gaps between orders for customers who have placed multiple orders. In order to achieve this I used CTE's.
### multiorder_customer CTE: This part finds customers who have placed more than one order and counts the number of distinct orders for each customer.
### order_dates CTE: This part retrieves the order dates for customers and filters them to only include those who have made multiple orders.
### days_between_orders CTE: This determines the time gaps between consecutive orders for each customer using the LAG function to get the previous order date by partioning (PARTITION BY) the data. It then calculates the number of days between orders using DATEDIFF and handles cases where there's no previous order date by using COALESCE to avoid NULL values.
### final query: Selects and summarizes the results using MIN, MAX and AVG.
```sql
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
```

## Question 9: Delete the table CTA.dbo.customers
### In this example I received an error that there was a foreign key constraint and I was not able to delete the table. In order to bypass this issue, I searched for the foreign key in the 'orders' table that linked the 'customers' table. Next, I used ALTER TABLE to remove the foreign key constraint (DROP CONSTRAINT). After, I was able to delete the 'customers' table (DROP TABLE).
```sql
SELECT name
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID('orders') AND OBJECT_NAME(referenced_object_id) = 'customers';

ALTER TABLE orders
DROP CONSTRAINT FK__orders__customer__47DBAE45;

DROP TABLE customers;
```