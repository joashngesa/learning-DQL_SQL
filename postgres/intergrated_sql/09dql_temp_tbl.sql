--Customer revenue to contain:
    --customer_key
    --total_revenue
    --total_orders

    --then query top 20 customers by revenues

CREATE TEMP TABLE customer_revenue AS
SELECT 
    customer_key,
    sum(sales) as total_revenues,
    count(DISTINCT order_id) as total_orders
FROM core.fact_order_item
GROUP BY customer_key;

SELECT
    customer_key,
    total_revenues,
    total_orders
FROM customer_revenue
ORDER BY total_revenues DESC
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
    sum(foi.sales) as total_customers
FROM core.fact_order_item AS foi
JOIN core.dim_customer AS dc
ON foi.customer_key = dc.customer_key
GROUP BY dc.customer_segment;

SELECT 
    segment,
    customer_count,
    ROUND(avg(total_customers),2) as avg_customer_revenue,
    CASE
        WHEN avg(total_customers) > 10000 THEN 'platinum'
        WHEN avg(total_customers) BETWEEN 5000 AND 10000 THEN 'gold'
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
CREATE VIEW mart.monthly_market_revenue AS
SELECT
    dd.year,
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
    dd.month_name,
    dol.market

--Check & test the view
SELECT *
   -- sum(tot_revenue) AS total_sales
FROM mart.monthly_market_revenue

--Calc 3-month rolling revenue per market from the view
SELECT
    year,
    month_name,
    market,
    sum(tot_revenue) OVER (PARTITION BY market ORDER BY year,month_name
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_revenue
FROM mart.monthly_market_revenue



--EXECUTIVE KPI DASHBOARD QUERY
--Output:
    --market
    --year
    --month
    --revenue
    --avg_order_value
    --late_delivery_rate
    --top_customer_revenue

WITH customer_monthly_revenue AS (
        SELECT 
            dol.market,
            dd.year,
            dd.month_name,
            dd.month,
            dc.customer_lname,
            sum(foi.sales) as customer_revenue,
            count(foi.order_id) as customer_orders,
            count(foi.order_id) FILTER (WHERE foi.delivery_status = 'Late delivery') AS late_delivery_count
        FROM core.fact_order_item as foi
        JOIN core.dim_order_location as dol
        ON foi.order_location_key = dol.order_location_key
        JOIN core.dim_date as dd
        ON foi.order_date_key = dd.date_key
        JOIN core.dim_customer as dc
        ON foi.customer_key = dc.customer_key
        GROUP BY 
            dol.market,
            dd.year,
            dd.month,
            dd.month_name,
            dc.customer_lname
),customer_ranking as (
SELECT
    year,
    month_name,
    month,
    market,
    customer_lname,
    customer_revenue,
    customer_orders,
    late_delivery_count,
    row_number() OVER (PARTITION BY market,month_name,year ORDER BY customer_revenue DESC) AS ranking
FROM customer_monthly_revenue
)
SELECT
    market,
    year,
    month,
    month_name,
    sum(customer_revenue) as revenue,
    round(sum(customer_revenue)::numeric / NULLIF(sum(customer_orders),0),2) as avg_order_value,
    round(sum(late_delivery_count)::numeric / NULLIF(sum(customer_orders),0),2) as late_delivery_rate,
    MAX(CASE WHEN ranking = 1 THEN customer_lname END) AS top_customer_name,
    MAX(CASE WHEN ranking = 1 THEN customer_revenue END) AS top_customer_revenue
FROM customer_ranking
GROUP BY year,month_name,month,market
ORDER BY year DESC, month DESC

