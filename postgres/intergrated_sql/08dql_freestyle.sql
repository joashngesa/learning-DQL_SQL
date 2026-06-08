

SELECT
    count(*)
FROM core.dim_product as dp
JOIN core.fact_order_item as foi
ON dp.product_key = foi.product_key
LIMIT 100


SELECT
    product_key,
    count(*)
FROM core.fact_order_item
GROUP BY product_key
HAVING count(*) > 1; 