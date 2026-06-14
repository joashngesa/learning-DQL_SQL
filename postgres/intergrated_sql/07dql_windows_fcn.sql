--Top 5 products per market by revenue
--output:
    --market
    --product_name
    --total_revenue
    --product_rank

WITH revenues AS (
        SELECT
            dol.order_country as market,
            dp.product_name,
            sum(sales) as total_revenue,
            rank() OVER(PARTITION BY dol.order_country ORDER BY SUM(sales) DESC) AS ranking
        FROM core.fact_order_item as foi
        JOIN core.dim_order_location as dol
        ON foi.order_location_key = dol.order_location_key
        JOIN core.dim_product as dp
        ON foi.product_key = dp.product_key
        GROUP BY dol.order_country,dp.product_name
)
        SELECT
            market,
            product_name,
            total_revenue,
            ranking
        FROM revenues
        WHERE ranking <= 5;



--Top 3 customers per customer segment
--return:
    --customer_segment
    --customer_key
    --customer_fname
    --customer_lname
    --total_revenue
    --customer_rank

WITH customer_revenue AS (
        SELECT 
            foi.customer_key,
            dc.customer_segment,
            dc.customer_fname,
            dc.customer_lname,
            SUM(foi.sales) AS total_revenues,
            row_number() OVER(PARTITION BY dc.customer_segment ORDER BY SUM(foi.sales) DESC) AS customer_rank
        FROM core.fact_order_item as foi
        JOIN core.dim_customer as dc
        ON foi.customer_key = dc.customer_key
        GROUP BY foi.customer_key,dc.customer_segment,dc.customer_fname,dc.customer_lname
)
        SELECT
            customer_key,
            customer_segment,
            customer_fname,
            customer_lname,
            total_revenues,
            customer_rank
        FROM customer_revenue
        WHERE customer_rank <= 3;




--Top 3 shipping modes by revenue by market
--Return:
    --market
    --shipping_mode
    --total_revenue
    --shipping_mode_rank

WITH revenue AS (
        SELECT
            dol.order_country,
            ds.shipping_mode,
            SUM(foi.sales) as total_revenues,
            row_number() OVER(PARTITION BY shipping_mode ORDER BY SUM(foi.sales)) as revenue_ranks
        FROM core.fact_order_item as foi
        JOIN core.dim_order_location as dol
        ON foi.order_location_key = dol.order_location_key
        JOIN core.dim_shipment as ds
        ON foi.shipment_key = ds.shipment_key
        GROUP BY ds.shipping_mode,dol.order_country
)
        SELECT 
            order_country,
            shipping_mode,
            total_revenues,
            revenue_ranks
        FROM revenue
        WHERE revenue_ranks <= 3; 





--Running monthly revenues by market
--aggregate revenue by market + year + month
--return:
    --market
    --year
    --month
    --month_name
    --monthly_revenue
    --running_market_revenue

SELECT 
    dol.order_country,
    dd.year as sales_year,
    dd.month,
    dd.month_name,
    SUM(foi.sales) as monthly_revenue,
    sum(sum(foi.sales)) OVER(PARTITION BY dol.order_country ORDER BY dd.year, dd.month) AS running_market_revenue
FROM core.fact_order_item as foi
JOIN core.dim_order_location as dol
ON foi.order_location_key = dol.order_location_key
JOIN core.dim_date as dd
ON foi.order_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name,
    dol.order_country
        





--Previous month revenue camparison by market
--return:
    --market
    --year
    --month
    --monthly_revenue
    --previous_month_revenue
    --revenue_difference

WITH revenues AS (
        SELECT 
            dol.order_country AS market,
            dd.year as sales_year,
            dd.month as month,
            dd.month_name,
            sum(foi.sales) as monthly_revenue
        FROM core.fact_order_item as foi
        JOIN core.dim_order_location as dol
        ON foi.order_location_key = dol.order_location_key
        JOIN core.dim_date as dd
        ON foi.order_date_key = dd.date_key
        GROUP BY 
            dd.year,
            dd.month,
            dd.month_name,
            dol.order_country
), revenue_difference AS (
        SELECT
            market,
            sales_year,
            month,
            month_name,
            monthly_revenue,
            lag(monthly_revenue) OVER (PARTITION BY market ORDER BY sales_year,month) as previous_month_revenue,
            (monthly_revenue - lag(monthly_revenue) OVER (PARTITION BY market ORDER BY sales_year,month)) AS revenue_difference
        FROM revenues
)
SELECT
    market,
    sales_year,
    month,
    month_name,
    monthly_revenue,
    previous_month_revenue,
    revenue_difference,
    CASE
        WHEN previous_month_revenue is NULL or previous_month_revenue = 0 THEN NULL
        ELSE
        ROUND((revenue_difference::NUMERIC / previous_month_revenue) * 100,2)
        END AS mom_growth_percentage
FROM revenue_difference



--Delivery risk dashboard by shipping mode
--return:
    --shipping_mode
    --total_order_items
    --avg_shipping_days
    --total_revenue
    --late_delivery_count
    --late_delivery_rate
    --risk_flag
        --Risky if avg_shipping_days > 4 OR late_delivery_rate > 0.30
        --Safe otherwise

WITH revenues AS (
        SELECT
            ds.shipping_mode,
            SUM(foi.order_item_quantity) total_order_items,
            round( avg(foi.days_for_shipping_real),2) as avg_shipping_days,
            sum(foi.sales) as total_revenue,
            count(foi.late_delivery_risk) FILTER (WHERE foi.late_delivery_risk = 'True') as late_delivery_count,
            count(*) as total_count
        FROM core.fact_order_item as foi
        JOIN core.dim_shipment as ds
        ON foi.shipment_key = ds.shipment_key
        GROUP BY ds.shipping_mode
), dashboard AS (
        SELECT
            shipping_mode,
            total_order_items,
            avg_shipping_days,
            total_revenue,
            late_delivery_count,
            total_count,
            round((late_delivery_count:: NUMERIC / total_count),2) as late_delivery_rate
        FROM revenues
)
SELECT
    shipping_mode,
    total_order_items,
    avg_shipping_days,
    total_revenue,
    late_delivery_count,
    late_delivery_rate,
    CASE
        WHEN avg_shipping_days > 4 or late_delivery_rate > 0.30
        THEN 'Risky'
        ELSE 'Safe'
        END AS risk_flag
    FROM dashboard
    ;

--you can also write the query as below:

WITH revenues AS (
    SELECT
        ds.shipping_mode,
        SUM(foi.order_item_quantity) AS total_order_items,
        ROUND(AVG(foi.days_for_shipping_real), 2) AS avg_shipping_days,
        SUM(foi.sales) AS total_revenue,
        -- FIX: Proper Boolean syntax (handles TRUE/FALSE types cleanly)
        COUNT(*) FILTER (WHERE foi.late_delivery_risk IS TRUE) AS late_delivery_count,
        COUNT(*) AS total_count
    FROM core.fact_order_item AS foi
    JOIN core.dim_shipment AS ds
    ON foi.shipment_key = ds.shipment_key
    GROUP BY ds.shipping_mode
)
SELECT
    shipping_mode,
    total_order_items,
    avg_shipping_days,
    total_revenue,
    late_delivery_count,
    -- FIX: Combined the redundant CTE math directly into the final select
    ROUND((late_delivery_count::NUMERIC / total_count), 2) AS late_delivery_rate,
    CASE
        WHEN avg_shipping_days > 4 OR (late_delivery_count::NUMERIC / total_count) > 0.30
        THEN 'Risky'
        ELSE 'Safe'
    END AS risk_flag
FROM revenues;



--MARKET-PRODUCT LEADERBOARD
--Top 5 highest revenue pe product for each country per year
--Requirements; Revenues per;
        --market
        --year
        --product_name
        --rank product inside each market + year
        --return only top 5
    --expected output:
        --market
        --year
        --product_name
        --category_key
        --total_revenue
        --product_rank

WITH product_revenue AS (
        SELECT
            dol.order_country as market,
            dd.year,
            dp.product_name,
            dp.category_key,
            sum(foi.sales) as total_revenue,
            row_number() OVER(PARTITION BY dol.order_country,dd.year ORDER BY sum(foi.sales) DESC) AS product_ranking
        FROM core.fact_order_item as foi
        JOIN core.dim_order_location as dol
        ON foi.order_location_key = dol.order_location_key
        JOIN core.dim_date as dd
        ON foi.order_date_key = dd.date_key
        JOIN core.dim_product as dp
        ON foi.product_key = dp.product_key
        GROUP BY 
             dd.year,
            dol.order_country,
            dp.product_name,
            dp.category_key
)
SELECT
    market,
    year,
    product_name,
    category_key,
    total_revenue,
    product_ranking
FROM product_revenue
WHERE product_ranking <= 5
ORDER BY 
    market,
    year,
    product_ranking
    ;





