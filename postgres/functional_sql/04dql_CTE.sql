
--write this using CTE
SELECT
    delivery_status,
    ROUND(AVG(total_orders), 2) AS avg_order_value
FROM (
    SELECT 
        order_id,
        delivery_status,
        SUM(sales) AS total_orders
    FROM core.fact_order_item
    GROUP BY order_id, delivery_status
) AS order_totals
GROUP BY delivery_status
ORDER BY avg_order_value DESC;

--CTE Version

WITH order_totals AS(
    SELECT
        order_id,
        delivery_status,
        sum(sales) as total_orders
    FROM core.fact_order_item
    GROUP BY order_id, delivery_status
)
SELECT 
    delivery_status,
    round(avg(total_orders),2) as average_sales
FROM order_totals
GROUP BY delivery_status
ORDER BY average_sales DESC
;


WITH order_totals AS (
    SELECT 
        order_id,
        delivery_status,
        SUM(sales) AS total_orders
    FROM core.fact_order_item
    GROUP BY order_id, delivery_status
)
SELECT
    delivery_status,
    ROUND(AVG(total_orders), 2) AS avg_order_value
FROM order_totals
GROUP BY delivery_status
ORDER BY avg_order_value DESC;


--High revenue orders; return only orders with total sales > 2000

WITH order_totals AS (
        SELECT 
            order_id,
            SUM(sales) as total_orders
        FROM core.fact_order_item
        GROUP BY order_id
    )
SELECT 
    order_id,
    total_orders
FROM order_totals
WHERE total_orders > 2000;


--LATE DELIVERY REVENUE
--find total revenue per delivery_status and 
--show only statuses with revenue > 100000

WITH total_revenues AS (
        SELECT
            delivery_status,
            SUM(sales) as total_sales
        FROM core.fact_order_item
        GROUP BY delivery_status
)
SELECT
    delivery_status,
    total_sales
FROM total_revenues
WHERE total_sales > 100000;


--AVERAGE QUANTITY PER PRODUCT
--total quantity sold per product

WITH quantity_orders AS (
        SELECT
            product_key,
            SUM(order_item_quantity) as total_quantity
        FROM core.fact_order_item
        GROUP BY product_key
)
SELECT 
    product_key,
    round(avg(total_quantity),2) as average_quantity
FROM quantity_orders
GROUP BY product_key
ORDER BY average_quantity DESC
limit 30;

--average quantity across all products

WITH quantity_orders AS (
        SELECT
            product_key,
            SUM(order_item_quantity) as total_quantity
        FROM core.fact_order_item
        GROUP BY product_key
)
SELECT 
    round(avg(total_quantity),2) as average_quantity
FROM quantity_orders
ORDER BY average_quantity DESC
limit 30;