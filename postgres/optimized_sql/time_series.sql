
--MONTHLY REVENUE GROWTH
--Expected output:
    --market
    --year
    --month
    --revenue
    --previous_month_revenue
    --revenue_difference
    --growth_rate

SELECT *
FROM mart.monthly_market_revenue;


WITH revenues AS (
    SELECT 
        market,
        year,
        month_name,
        tot_revenue,
        coalesce(lag(tot_revenue) OVER (PARTITION BY market ORDER BY year,month_name),0) as previous_month_revenue,
        (tot_revenue - coalesce(lag(tot_revenue) OVER (PARTITION BY market ORDER BY year,month_name))) as revenue_difference
    FROM mart. monthly_market_revenue       
)
SELECT
    market,
    year,
    month_name,
    tot_revenue,
    previous_month_revenue,
    revenue_difference,
    ROUND(revenue_difference::numeric / NULLIF(previous_month_revenue,0),2) as growth_rate
FROM revenues




--RUNNING REVENUE KPI
--Output:
    --market
    --year
    --month
    --revenue
    --running_market_revenue

SELECT
    market,
    year,
    month_name,
    tot_revenue as revenue,
    sum(tot_revenue) OVER (PARTITION BY market ORDER BY year,month_name) as running_market_revenue
FROM mart.monthly_market_revenue




--ROLLING REVENUE KPI
--Output:
    --market
    --year
    --month
    --revenue
    --3_month_rolling_revenue

SELECT
    market,
    year,
    month_name as month,
    tot_revenue as revenue,
    sum(tot_revenue) OVER (PARTITION BY market ORDER BY year,month_name
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as "3_month_rolling_revenue"
FROM mart.monthly_market_revenue




--MOVING AVERAGE KPI
--Output:
    --market
    --year
    --month
    --revenue
    --3_month_moving_avg

SELECT
    market,
    year,
    month_name as month,
    tot_revenue as revenue,
    round(avg(tot_revenue) OVER (PARTITION BY market ORDER BY year, month_name
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) as "3_month_moving_avg"
FROM mart.monthly_market_revenue




--MARKET TREND DASHBOARD
--output:
    --market
    --year
    --month
    --revenue
    --growth_rate
    --running_total
    --moving_average

WITH revenues AS (
        SELECT
            market,
            year,
            month_name AS month,
            tot_revenue as revenue,
            COALESCE(lag(tot_revenue) OVER(PARTITION BY market ORDER BY year, month_name),0) as previous_revenue,
            (tot_revenue - COALESCE(lag(tot_revenue) OVER(PARTITION BY market ORDER BY year, month_name),0)) AS difference
        FROM mart.monthly_market_revenue
)
SELECT 
    market,
    year,
    month,
    revenue,
    ROUND(difference::NUMERIC / NULLIF(previous_revenue,0),2) AS growth_rate,
    sum(revenue) OVER(PARTITION BY market ORDER BY year, month) AS running_total,
    round(avg(revenue) OVER(PARTITION BY market ORDER BY year, month),2) AS moving_average
FROM revenues



--CUSTOMER LIFETIME KPI
--Output:
    --customer_key
    --first_purchase_date
    --latest_purchase_date
    --lifetime_revenue
    --total_orders
    -- avg_order_value

    SELECT
        foi.customer_key,
        foi.order_id,
        MIN(dd.full_date) AS first_purchase_date,
        max(dd.full_date) AS latest_purchase_date,
        sum(foi.sales) AS lifetime_revenue,
        count(DISTINCT foi.order_id) as total_orders,
        round(sum(foi.sales)::NUMERIC / count(DISTINCT foi.order_id),2) AS avg_order_value
    FROM core.fact_order_item AS foi
    JOIN core.dim_date AS dd
    ON foi.order_date_key = dd.date_key
    GROUP BY 
        foi.customer_key,
        foi.order_id





--COHORT FOUNDATION
--Output:
    --customer_key
    --first_purchase_month

SELECT
    foi.customer_key,
    date_trunc('month',min(dd.full_date)) AS first_purchase_month
FROM core.fact_order_item AS foi
JOIN core.dim_date AS dd
ON foi.order_date_key = dd.date_key
GROUP BY foi.customer_key