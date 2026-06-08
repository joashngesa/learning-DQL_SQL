--Total sales across all data
select sum(sales) as total_sales
from core.fact_order_item
;


--How much revenue comes from each delivery_status?
select 
    delivery_status,
    sum(sales) as revenue
from core.fact_order_item
group by delivery_status;


--Count how many order items exist
select count(order_item_id)
from core.fact_order_item;


--Total sales per order_id
select order_id,
    sum(sales) as tot_sales_per_order 
from core.fact_order_item
group by order_id
order by tot_sales_per_order desc
limit 20


--top 5 top sales by order_id
select order_id,
    sum(sales) as tot_sales_per_order 
from core.fact_order_item
group by order_id
order by tot_sales_per_order DESC
limit 5


--Average sales per order_id
select order_id,
    round(avg(sales),2) as average_sales
from core.fact_order_item
group by order_id
order by average_sales 
limit 20


--Orders with total sales > 1000
select order_id,
    sum(sales) as total_sales
from core.fact_order_item
group by order_id
having sum(sales) > 1000;

--Top 5 delivery_status categories by total revenue
--Only include those with revenue > 10,000
SELECT 
    delivery_status,
    SUM(sales) as total_sales
FROM core.fact_order_item
GROUP BY delivery_status
HAVING SUM(sales) > 10000
ORDER BY total_sales DESC
limit 5


--average sales per order_id
select
    round(avg(order_total), 2) as average_order_value
from (
    select
        order_id,
        sum(sales) as order_total
    from core.fact_order_item
    group by order_id
) as order_totals;