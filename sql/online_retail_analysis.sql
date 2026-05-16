create view kpi_summary as
select
	sum(revenue) as total_revenue,
	count(distinct invoice_no) filter(where is_return=false) as total_orders,
	count(distinct customer_id) filter(where customer_id is not null and is_return=false) as total_active_customers,
	count(distinct description) as no_of_products,
	sum(revenue) / nullif(count(distinct invoice_no) filter(where is_return=false), 0) as net_aov,
	sum(revenue) filter(where customer_id is not null)/nullif(count(distinct customer_id) filter(where customer_id is not null and is_return=false),0) as revenue_per_active_customer
from online_retail_data;

------------------------------------------------------------------------------------------

create view monthly as
select 
	year_month,
	sum(revenue) as monthly_revenue,
	count(distinct invoice_no) filter(where is_return=false) as monthly_orders,
	count(distinct customer_id) filter(where customer_id is not null and is_return=false) as monthly_customers,
	sum(revenue)/ nullif(count(distinct invoice_no) filter(where is_return=false), 0) as monthly_net_aov
from online_retail_data
group by year_month;

create view monthly_growth as
select 
	year_month,
	monthly_revenue,
	lag(monthly_revenue) over (order by year_month) as prev_monthly_revenue,
	100.0 * (monthly_revenue - lag(monthly_revenue) over (order by year_month))/ nullif(lag(monthly_revenue) over (order by year_month), 0) as mom_revenue_growth
from monthly;


create view new_customers_monthly as
with first_purchase as 
	(select
		customer_id, 
		min(invoice_date) as first_purchase_date,
		to_char(min(invoice_date), 'YYYY-MM') as first_year_month
	from online_retail_data
	where customer_id is not null and is_return=false
	group by customer_id
	)
select 
	first_year_month,
	count(customer_id) as new_customers
from first_purchase
group by first_year_month;


create view new_customer_revenue_monthly as
with first_purchase as (
    select
        customer_id,
        min(invoice_date) as first_purchase_date,
        to_char(min(invoice_date), 'YYYY-MM') as first_year_month
    from online_retail_data
    where customer_id is not null
      and is_return = false
    group by customer_id
),
sales_with_first_month as (
    select
        d.customer_id,
        d.year_month,
        d.revenue,
        fp.first_year_month
    from online_retail_data d
    join first_purchase fp
        on d.customer_id = fp.customer_id
    where d.customer_id is not null
)
select
    year_month,
    sum(revenue) as revenue_from_new_customers
from sales_with_first_month
where year_month = first_year_month
group by year_month;




create view customer_behavior as
select
	customer_id,
	sum(revenue) as revenue_per_customer,
	count(distinct invoice_no) filter(where is_return=false) as orders_per_customer,
	max(invoice_date) filter(where is_return=false) as last_purchase_date
from online_retail_data
where customer_id is not null
group by customer_id;

create view average_orders_per_customer as
select
	avg(orders_per_customer)  as avg_orders_per_customer
from customer_behavior;

create view customer_repeat_summary as
select
	count(*) as total_customers,
	count(customer_id) filter(where orders_per_customer>1) as repeat_customers,
	count(customer_id) filter(where orders_per_customer=1) as one_time_customers,
	count(customer_id) filter(where orders_per_customer>1)::numeric/count(*) as repeat_rate,
	sum(revenue_per_customer) filter(where orders_per_customer>1) as revenue_from_repeat,
	sum(revenue_per_customer) filter(where orders_per_customer=1) as revenue_from_one_time,
	sum(revenue_per_customer) filter(where orders_per_customer>1)::numeric/sum(revenue_per_customer)*100.0 as repeat_share,
	sum(revenue_per_customer) filter(where orders_per_customer=1)::numeric/sum(revenue_per_customer)*100.0 as one_time_share
from customer_behavior;



create view country_analytics as
select
	country,
	sum(revenue) as country_revenue,
	count(distinct invoice_no) filter(where is_return=false) as country_orders
from online_retail_data
group by country;



create view product_analytics as
select 
	stock_code,
	description,
	sum(revenue) as revenue_by_product,
	sum(quantity) as quantity_by_product
from online_retail_data
group by stock_code, description; 

create view top_products as 
select 
	stock_code,
	description,
	revenue_by_product
from product_analytics
order by revenue_by_product desc limit 10;

create view top_products_by_month as
with product_monthly as (
	select 
		year_month,
		stock_code,
		description, 
		sum(revenue) as product_revenue
	from online_retail_data 
	group by year_month, stock_code, description
)
select *
from(
	select
		year_month,
		stock_code,
		description,
		product_revenue,
		row_number() over(
		partition by year_month
		order by product_revenue desc) as rank
	from product_monthly
) t
where rank<=3;




create view category_analytics as 
select 
	category,
	sum(revenue) as category_revenue,
	count(distinct invoice_no) as category_orders,
	count(distinct customer_id) as active_category_customers,
	sum(revenue)/ nullif(count(distinct invoice_no), 0) as category_aov
from online_retail_data
where is_return=false and customer_id is not null
group by category;


create view category_by_month as
select 
	year_month,
	category,
	sum(revenue) as monthly_revenue_by_category,
	count(distinct invoice_no) filter(where is_return=false) as monthly_orders_by_category,
	count(distinct customer_id) filter(where is_return=false) as active_monthly_customers_by_category,
	sum(revenue)/ nullif(count(distinct invoice_no) filter(where is_return=false), 0) as monthly_category_aov
from online_retail_data
where customer_id is not null
group by year_month, category;


create view category_monthly_growth as
select 
	category,
	year_month,
	monthly_revenue_by_category,
	lag(monthly_revenue_by_category) over (partition by category order by year_month) as prev_monthly_revenue_by_category,
	100.0 * (monthly_revenue_by_category - lag(monthly_revenue_by_category) over (partition by category order by year_month))/nullif(lag(monthly_revenue_by_category) over (partition by category order by year_month),0) as mom_revenue_growth_by_category
from category_by_month;


create view monthly_customer_status_revenue as
with first_purchase as (
    select
        customer_id,
        to_char(min(invoice_date), 'YYYY-MM') as first_year_month
    from online_retail_data
    where customer_id is not null
      and is_return = false
    group by customer_id
),
sales_with_status as (
    select
        d.year_month,
        d.customer_id,
        d.revenue,
        d.is_return,
        case
            when d.year_month = fp.first_year_month then 'new'
            else 'repeat'
        end as customer_status
    from online_retail_data d
    join first_purchase fp
        on d.customer_id = fp.customer_id
    where d.customer_id is not null
      
)
select
    year_month,
    sum(revenue) filter (where customer_status = 'new') as revenue_from_new,
    sum(revenue) filter (where customer_status = 'repeat') as revenue_from_repeat,
    count(distinct customer_id) filter (where customer_status = 'new' and is_return=false) as new_customers,
    count(distinct customer_id) filter (where customer_status = 'repeat' and is_return=false) as repeat_customers
from sales_with_status
group by year_month;


create view monthly_growth_decomposition as
with monthly_base as (
    select
        year_month,
        sum(revenue) as monthly_revenue,
        count(distinct invoice_no) filter(where is_return=false) as monthly_orders,
        count(distinct customer_id) filter(where is_return=false) as monthly_customers,
        sum(revenue) / nullif(count(distinct invoice_no) filter(where is_return=false), 0) as monthly_aov,
        count(distinct invoice_no) filter(where is_return=false)::numeric  / nullif(count(distinct customer_id) filter(where is_return=false) , 0) as orders_per_customer
    from online_retail_data
    where customer_id is not null
    group by year_month
),
monthly_split as (
    select
        year_month,
        revenue_from_new,
        revenue_from_repeat,
        new_customers,
        repeat_customers
    from monthly_customer_status_revenue
)
select
    mb.year_month,
    mb.monthly_revenue,
    lag(mb.monthly_revenue) over (order by mb.year_month) as prev_monthly_revenue,
    100.0 * (
        mb.monthly_revenue - lag(mb.monthly_revenue) over (order by mb.year_month)
    ) / nullif(lag(mb.monthly_revenue) over (order by mb.year_month), 0) as mom_revenue_growth_pct,
    mb.monthly_orders,
    mb.monthly_customers,
    mb.monthly_aov,
    mb.orders_per_customer,
    ms.revenue_from_new,
    ms.revenue_from_repeat,
    ms.new_customers,
    ms.repeat_customers,
    ms.revenue_from_new / nullif(mb.monthly_revenue, 0) as new_revenue_share,
    ms.revenue_from_repeat / nullif(mb.monthly_revenue, 0) as repeat_revenue_share
from monthly_base mb
left join monthly_split ms
    on mb.year_month = ms.year_month;


create view rfm_base as
with max_date_cte as (
    select max(invoice_date) as max_date
    from online_retail_data
    where is_return = false
)
select
    cb.customer_id,
    cb.revenue_per_customer as monetary,
    cb.orders_per_customer as frequency,
    (md.max_date::date - cb.last_purchase_date::date) as recency
from customer_behavior cb
cross join max_date_cte md;


create view rfm_scored as
select
    customer_id,
    recency,
    frequency,
    monetary,

    ntile(3) over (order by recency desc) as recency_score,
    ntile(3) over (order by frequency asc) as frequency_score,
    ntile(3) over (order by monetary asc) as monetary_score
from rfm_base;


create view rfm_segments as
select
    customer_id,
    recency,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    recency_score + frequency_score + monetary_score as rfm_total_score,
    case
        when recency_score = 3 and frequency_score = 3 and monetary_score = 3 then 'Champions'
        when frequency_score >= 2 and monetary_score >= 2 and recency_score >= 2 then 'Loyal Customers'
        when recency_score = 3 and frequency_score = 1 then 'New Customers'
        when recency_score = 1 and monetary_score >= 2 then 'At Risk'
        else 'Regular Customers'
    end as rfm_segment
from rfm_scored;


create view rfm_analytics as
select
    r.rfm_segment,
    count(distinct r.customer_id) as customers,
    sum(cb.revenue_per_customer) as revenue,
    avg(cb.revenue_per_customer) as avg_revenue_per_customer
from rfm_segments r
join customer_behavior cb
    on r.customer_id = cb.customer_id
group by r.rfm_segment;