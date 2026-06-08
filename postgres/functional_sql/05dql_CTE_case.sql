--WINDOWS FUNCTIONS, CASE AND CTE.

--Create a query that shows:
    --order_id
    --order_item_id
    --sales
    --sales_category
--rules:
    --sales >= 1000 → High
    --sales >= 500 → Medium
    --else → Low

SELECT
    order_id,
    order_item_id,
    sales,
    CASE
        WHEN sales >= 1000 THEN 'high'
        WHEN sales >= 500 THEN 'medium'
        ELSE 'low'
        END AS sales_category
FROM core.fact_order_item
;


--Count sales category
--classify each row by sales category, then count rows in each category.

WITH sales_category AS (
        SELECT
    order_id,
    order_item_id,
    sales,
    CASE
        WHEN sales >= 1000 THEN 'high'
        WHEN sales >= 500 THEN 'medium'
        ELSE 'low'
        END AS category_sales
FROM core.fact_order_item
)
SELECT 
    category_sales,
    COUNT(*)
FROM sales_category
GROUP BY category_sales;


--Calculate total revenue per customer_key
--Classify:
--> 5000 = High Value
--2000 to 5000 = Medium Value
--< 2000 = Low Value
--Count customers per segment

WITH total_revenue AS (
        SELECT 
            customer_key,
            SUM(sales) as revenue
        FROM core.fact_order_item
        GROUP BY customer_key
),
    category_customer as (
    SELECT 
        customer_key,
        CASE
            WHEN revenue > 5000 THEN 'High value'
            WHEN revenue BETWEEN 2000 AND 5000 THEN 'Medium value'
            else 'low value'
            END AS customer_category
        FROM total_revenue
 )
SELECT 
    customer_category,
    COUNT(*) category_count
FROM category_customer
GROUP BY customer_category;


--show the below in the output
    --order_id
    --customer_key
    --sales
    --total customer sales beside each row

SELECT
    order_id,
    customer_key,
    SUM(sales) OVER (PARTITION BY customer_key) as customer_sales
FROM core.fact_order_item
limit 30;


--Running totals for each customer over time

SELECT
    customer_key,
    SUM(sales) OVER (PARTITION BY customer_key ORDER BY order_date_key ) accumulative_sales_totals
FROM core.fact_order_item
limit 30;


--Previous order comparison
--expected columns;
    --current sales
    --previous sales
    --difference

WITH orders AS (
SELECT
    customer_key,
    order_id,
    order_date_key,
    sales,
    lag(sales) OVER(PARTITION BY customer_key ORDER BY order_date_key) as previous_sales
FROM core.fact_order_item
    )
SELECT
    customer_key,
    order_id,
    order_date_key,
    sales,
    previous_sales,
    (sales - previous_sales) as sales_difference
FROM orders;



--🔥 Drill 5 — Top Products Per Category
--Calculate:
--revenue per product
--Rank products within each category
--Final:
--Return top 3 products per category

--the data above will be hard to answer becaust the table is a fact table, it has 
--no category, unless i join it with a dimension product table


--🔥 Drill 6 — Delivery Risk Analysis
--CTE 1:
--Calculate:
    --average shipping days per delivery_status
--CTE 2:
--Flag:
    --“Risky” if avg shipping > 4
    --“Safe” otherwise
--Final:
--Return:
    --delivery_status
    --avg_shipping_days
    --risk_flag

WITH shipping_average AS (
SELECT 
    ROUND(AVG(days_for_shipping_real),2) as avg_shipping,
    delivery_status
FROM core.fact_order_item
GROUP BY delivery_status),
shipping_flag AS (
    SELECT 
        delivery_status,
        avg_shipping,
        CASE
            WHEN avg_shipping > 4 THEN 'Risky'
            ELSE 'Safe'
            END AS risk_flag
    FROM shipping_average
)
SELECT 
    delivery_status,
    avg_shipping,
    risk_flag
FROM shipping_flag

