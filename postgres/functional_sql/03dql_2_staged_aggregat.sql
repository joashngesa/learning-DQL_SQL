--calculate the maximum order values/highest order total
SELECT
    MAX(total_orders) max_order_value
FROM
   ( SELECT
        order_id,
        sum(sales) as total_orders
    FROM core.fact_order_item
    GROUP BY order_id
   ) as tot_ord

--minimum order value/smallest order total
SELECT
    MIN(total_orders) as min_order_value
FROM
    (
    SELECT 
        order_id,
        SUM(sales) as total_orders
    FROM core.fact_order_item
    GROUP BY order_id
            ) tot_ords


--orders above average

SELECT
    order_id,
    total_orders
FROM (
    SELECT
        order_id,
        SUM(sales) AS total_orders
    FROM core.fact_order_item
    GROUP BY order_id
) AS order_totals
WHERE total_orders > (
    SELECT
        AVG(total_orders)
    FROM (
        SELECT
            order_id,
            SUM(sales) AS total_orders
        FROM core.fact_order_item
        GROUP BY order_id
    ) AS avg_orders
)
ORDER BY total_orders DESC
LIMIT 50;


--Average order value per delivery_status
SELECT
    delivery_status,
    ROUND(AVG(total_orders), 2) as avg_order_value
FROM
    (
    SELECT 
        order_id,
        delivery_status,
        SUM(sales) as total_orders
    FROM core.fact_order_item
    GROUP BY order_id, delivery_status
            ) tot_ords
GROUP BY delivery_status
ORDER BY avg_order_value DESC




