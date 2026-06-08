--select sales > 500
select sales,
    order_id,
    order_item_id
from core.fact_order_item
where sales > 500;


--sales > 500 and delivery_status = 'Late delivery'
select sales,
	delivery_status
from core.fact_order_item
where sales > 500 and delivery_status ilike 'late delivery'
LIMIT 20;


--changed late_delivery_risk to delivery_status because the former has error values
--sales > 500 or delivery_status = 'late delivery'
select sales,  
    delivery_status
from core.fact_order_item
where sales > 500 or 
    delivery_status ilike 'late delivery';


--sales > 500 and (delivery_status = 'Late_delivery' OR days_for_shipping_real < 2)
select sales,
    delivery_status,
    days_for_shipping_real
from core.fact_order_item
where sales > 500 and 
    (delivery_status ilike 'late delivery' and days_for_shipping_real < 2)
limit 20


--Top 10 highest sales orders
select sales 
from core.fact_order_item
order by sales DESC
limit 10;


--Lowest 5 profit orders
select sales
from core.fact_order_item
order by sales
limit 5;


--Get unique list of delivery_status values
select DISTINCT delivery_status
from core.fact_order_item;

--order_id ,sales as revenue
select order_id,
    sales,
    order_item_quantity,
    benefit_per_order
from core.fact_order_item
ORDER BY sales
LIMIT 30;


--Get the top 5 late orders by sales; Where delivery_status = 'Late delivery'
--Sort by highest sales
select order_id,
    SUM(sales) as total_sales,
    delivery_status
from core.fact_order_item
where delivery_status ilike 'late delivery'
GROUP BY order_id, delivery_status
order by total_sales DESC
limit 55;

