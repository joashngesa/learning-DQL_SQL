--Customer revenue to contain:
    --customer_key
    --total_revenue
    --total_orders

    --then query top 20 customers by revenues

CREATE TEMP TABLE customer_revenue AS
SELECT 
    customer_key,
    sum(sales) as customer_revenues,
    count(DISTINCT order_id) as total_orders
FROM core.fact_order_item
GROUP BY customer_key;

SELECT
    customer_key,
    customer_revenues,
    total_orders
FROM customer_revenue
ORDER BY customer_revenues DESC
LIMIT 20;


--CUSTOMER SEGMENTATION REUSE
--Classification:
    --Platinum > 10000
    --Gold 5000–10000
    --Silver < 5000
--return 
    --segment
    --customer_count
    --avg_customer_revenue
CREATE TEMP TABLE customer_revenues AS 
SELECT
    dc.customer_segment AS segment,
    COUNT(DISTINCT foi.customer_key) AS customer_count,
    sum(foi.sales) as customer_sales
FROM core.fact_order_item AS foi
JOIN core.dim_customer AS dc
ON foi.customer_key = dc.customer_key
GROUP BY dc.customer_segment;

SELECT 
    segment,
    customer_count,
    ROUND(avg(customer_sales),2) as avg_customer_revenue,
    CASE
        WHEN avg(customer_sales) > 10000 THEN 'platinum'
        WHEN avg(customer_sales) BETWEEN 5000 AND 10000 THEN 'gold'
        ELSE 'silver'
        END AS classification
FROM customer_revenues
GROUP BY segment,customer_count;



--CREATE MONTHLY MARKET REVENUE VIEW
--OUTPUT:
    --year
    --month
    --market
    --total_revenue
    --total_orders

--Delete the original view that does not have month

DROP VIEW IF EXISTS mart.monthly_market_revenue;

CREATE VIEW mart.monthly_market_revenue AS
SELECT
    dd.year,
    dd.month,
    dd.month_name,
    dol.market,
    SUM(foi.sales) as tot_revenue,
    count(DISTINCT foi.order_id) as tot_orders
FROM core.fact_order_item AS foi
JOIN core.dim_date as dd
ON foi.order_date_key = dd.date_key
JOIN core.dim_order_location AS dol
ON foi.order_location_key = dol.order_location_key
GROUP BY 
    dd.year,
    dd.month,
    dd.month_name,
    dol.market
    ;

--Check & test the view
SELECT *
FROM mart.monthly_market_revenue

--Calc 3-month rolling revenue per market from the view
SELECT
    year,
    month_name,
    market,
    sum(tot_revenue) OVER (PARTITION BY market ORDER BY year,month_name
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_revenue
FROM mart.monthly_market_revenue
    ;


--EXECUTIVE KPI DASHBOARD QUERY
--Output:
    --market
    --year
    --month
    --revenue
    --avg_order_value
    --late_delivery_rate
    --top_customer_revenue

SELECT  DISTINCT
    late_delivery_risk, 
    delivery_status
FROM core.fact_order_item
limit 60
    ;

WITH customer_monthly_sales AS (
    SELECT 
        dol.market,
        dd.year,
        dd.month,
        dd.month_name,
        foi.order_id,
        foi.sales,
        foi.delivery_status,
        -- Calculate individual total spend per customer per month
        SUM(foi.sales) OVER(PARTITION BY dol.market, dd.year, dd.month, foi.customer_key) AS individual_revenue,
        -- Rank customers to find the highest spender (#1) in each market and month
        ROW_NUMBER() OVER(
            PARTITION BY dol.market, dd.year, dd.month 
            ORDER BY SUM(foi.sales) DESC
        ) AS customer_spend_rank
    FROM core.fact_order_item AS foi
    JOIN core.dim_order_location AS dol ON foi.order_location_key = dol.order_location_key
    JOIN core.dim_date AS dd ON foi.order_date_key = dd.date_key
)
SELECT 
    market,
    year,
    month_name,
    month,
    -- Market-level aggregates (Your original columns)
    SUM(sales) AS monthly_revenue,
    COUNT(DISTINCT order_id) AS customer_orders,
    ROUND(SUM(sales)::NUMERIC / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    COUNT(delivery_status) FILTER (WHERE delivery_status = 'Late delivery') AS late_delivery_count,
    COUNT(delivery_status) AS total_deliveries,
    
    -- NEW COLUMN: Isolates and displays the revenue of the top customer
    MAX(individual_revenue) FILTER (WHERE customer_spend_rank = 1) AS top_customer_revenue,
    
    -- Market rank based on total revenue (Your original column)
    ROW_NUMBER() OVER(PARTITION BY market ORDER BY SUM(sales) DESC) AS ranking
FROM customer_monthly_sales
GROUP BY 
    market,
    year,
    month,
    month_name
ORDER BY 
    market, 
    year, 
    month;


