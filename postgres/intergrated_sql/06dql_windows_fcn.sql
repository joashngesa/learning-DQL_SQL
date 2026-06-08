--TESTING WINDOWS FUNCTIONS

--EXPECTED OUTPUT
    --customer_key
    --order_id
    --sales
    --sales_rank_per_customer

WITH order_customer AS (
        SELECT
            customer_key,
            order_id,
            sum(sales) as total_sales
        FROM core.fact_order_item
        GROUP BY customer_key,order_id
), sales_ranking AS (
        SELECT 
            customer_key,
            order_id,
            total_sales,
            row_number() OVER(PARTITION BY customer_key ORDER BY total_sales) as customer_ranking
        FROM order_customer
)
SELECT 
    customer_key,
    order_id,
    total_sales,
    customer_ranking
FROM sales_ranking
LIMIT 60;



--USE RANK()

WITH customer_order AS (
    SELECT 
        customer_key,
        order_id,
        SUM(sales) as tot_sales
    FROM core.fact_order_item
    GROUP BY customer_key,order_id
), ranking AS (
    SELECT
        customer_key,
        order_id,
        tot_sales,
        rank() OVER(PARTITION BY customer_key ORDER BY tot_sales) as ranking
    FROM customer_order
) 
SELECT 
    customer_key,
    order_id,
    tot_sales,
    ranking
FROM ranking
LIMIT 70;



--Top 3 highest sales orders per customer
--expected final output:
    --customer_key
    --order_id
    --sales
    --sales_rank

with customer_sales as (
    select
        customer_key,
        order_id,
        sum(sales) as total_sales
    from core.fact_order_item
    group by customer_key,order_id
), s_ranking as (
    select
        customer_key,
        order_id,
        total_sales,
        rank() OVER(PARTITION BY customer_key ORDER BY total_sales) as customer_ranking
    from customer_sales
)
select 
    customer_key,
    order_id,
    total_sales,
    customer_ranking
from s_ranking
where customer_ranking <= 3;



--Top 2 customers per market
--total revenue

with revenues as (
        select 
            customer_key,
            order_id,
            sum(sales) as total_revenues
        from core.fact_order_item
        group by customer_key,order_id
),  ranking as (
        select
            customer_key,
            order_id,
            total_revenues,
            rank() OVER(PARTITION BY customer_key ORDER BY total_revenues) as ranking
        from revenues
)
select
    customer_key,
    order_id,
    total_revenues,
    ranking
from ranking
where ranking <= 2;


