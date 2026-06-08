--MONTHLY PRODUCT KPI DASHBOARD
--Return:
    --market
    --year
    --month
    --revenue
    --total_orders
    --top_product_name
    --top_product_revenue

WITH monthly_product AS (
    SELECT
        dol.market,
        dd.year,
        dd.month,
        dd.month_name,
        dp.product_name,
        sum(foi.sales) as product_revenue,
        count(distinct foi.order_id) as total_orders,
        row_number() over(partition by dol.market,dd.year,dd.month order by sum(foi.sales) DESC) AS ranking
    FROM core.fact_order_item AS foi
    JOIN core.dim_order_location AS dol
    ON foi.order_location_key = dol.order_location_key
    JOIN core.dim_date AS dd
    ON foi.order_date_key = dd.date_key
    JOIN core.dim_product AS dp
    ON foi.product_key = dp.product_key
    GROUP BY 
        dol.market,
        dd.year,
        dd.month,
        dd.month_name,
        dp.product_name
)
SELECT 
    market,
    year,
    month_name,
    sum(total_orders) AS total_orders,
    sum(product_revenue) AS revenue,
    max(CASE WHEN ranking = 1 THEN product_name END) AS top_product_name,
    max(CASE WHEN ranking = 1 THEN product_revenue END) AS top_product_revenue
FROM monthly_product 
GROUP BY
    year,
    month_name,
    market
;



--MONTHLY SHIPPING KPI DASHBOARD
--Output:
    --market
    --year
    --month
    --revenue
    --avg_shipping_days
    --late_delivery_rate
    --top_shipping_mode
    --top_shipping_mode_revenue
WITH monthly_shipping AS (
        SELECT
            dol.market,
            dd.year,
            dd.month,
            dd.month_name,
            ds.shipping_mode,
            sum(foi.days_for_shipping_real) AS tot_shipping_days,
            sum(foi.sales) AS revenue,
            count(foi.order_id) AS total_orders,
            sum(CASE WHEN foi.delivery_status = 'Late delivery' THEN 1 ELSE 0 END) AS late_delivery_count,
            row_number() OVER(PARTITION BY dol.market,dd.year,dd.month ORDER BY sum(foi.sales)DESC) AS ranking
        FROM core.fact_order_item AS foi
        JOIN core.dim_order_location AS dol
        ON foi.order_location_key = dol.order_location_key
        JOIN core.dim_date AS dd
        ON foi.order_date_key = dd.date_key
        JOIN core.dim_shipment AS ds
        ON foi.shipment_key = ds.shipment_key
        GROUP BY 
            dd.year,
            dd.month,
            dd.month_name,
            dol.market,
            ds.shipping_mode
)
SELECT
    market,
    year,
    month_name,
    SUM(revenue) AS revenue,
    round(SUM(tot_shipping_days)::numeric / NULLIF(SUM(total_orders),0),2) AS avg_shipping_days,
    round(SUM(late_delivery_count)::numeric / NULLIF(SUM(total_orders),0),2) AS late_delivery_rate,
    MAX(CASE WHEN ranking = 1 THEN shipping_mode END) AS top_shipping_mode,
    MAX(CASE WHEN ranking = 1 THEN revenue END) AS top_shipping_mode_revenue
FROM monthly_shipping
GROUP BY
    year,
    month_name,
    market
ORDER BY year,market
;
--in the results, all the shipping mode was standard class, i suspect this is an error more than a coincidence
--The results of the table below show why the kpi is dominated by standard class
select  
    ds.shipping_mode,
    to_char(sum(foi.sales), 'FM999,999,999.99') AS sales
from core.fact_order_item as foi
join core.dim_shipment as ds
on foi.shipment_key = ds.shipment_key
group by ds.shipping_mode


--CUSTOMER SEGMENT KPI DASHBOARD
--Return:
    --customer_segment
    --year
    --month
    --revenue
    --customer_count
    --avg_revenue_per_customer
    --top_customer_key
    --top_customer_revenue
WITH customer_revenues AS (
        SELECT
            dc.customer_segment,
            dd.year,
            dd.month,
            dd.month_name,
            foi.customer_key,
            sum(foi.sales) AS revenue,
            row_number() OVER(PARTITION BY dc.customer_segment,dd.year,dd.month ORDER BY sum(foi.sales) DESC) as ranking
        FROM core.fact_order_item as foi
        JOIN core.dim_customer as dc
        ON foi.customer_key = dc.customer_key
        JOIN core.dim_date as dd
        ON foi.order_date_key = dd.date_key
        GROUP BY 
            dd.year,
            dd.month,
            dc.customer_segment,
            dd.month_name,
            foi.customer_key
        ORDER BY foi.customer_key DESC
)
SELECT
    year,
    month,
    month_name,
    customer_segment,
    sum(revenue)as revenue,
    count(distinct customer_key) AS customer_count,
    round(sum(revenue)::numeric / NULLIF(count(distinct customer_key),0),2) AS avg_revenue_per_customer,
    max(CASE WHEN ranking = 1 THEN customer_key END) AS top_customer_key,
    max(CASE WHEN ranking = 1 THEN revenue END) AS top_customer_revenue
FROM customer_revenues
GROUP BY 
    year,
    month,
    month_name,
    customer_segment
    ORDER BY
        year,
        month,
        customer_segment







--MART BASED KPI QUERY
SELECT
    *
FROM mart.monthly_market_revenue;
--RETUN:
    --market
    --year
    --month
    --total_revenue
    --previous_month_revenue
    --revenue_difference
    --revenue_growth_rate
    --3_month_rolling_revenue



select 
    market,
    year,
    month_name,
    tot_revenue,
    coalesce(lag(tot_revenue) over(partition by market order by year,month_name),0) as previous_month_revenue,
    (tot_revenue - coalesce(lag(tot_revenue) over(partition by market order by year,month_name),0)) as revenue_difference,
    round((tot_revenue - coalesce(lag(tot_revenue) over(partition by market order by year,month_name),0))::numeric
     / nullif(coalesce(lag(tot_revenue) over(partition by market order by year,month_name),0),0),2) as revenue_growth_rate,
    sum(tot_revenue) over (partition by market order by year, month_name
    rows between 2 preceding and current row ) as "3_month_rolling_revenue"
from mart.monthly_market_revenue