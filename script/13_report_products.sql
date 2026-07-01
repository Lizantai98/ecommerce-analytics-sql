/* 
============================================================================================================
Product Report
============================================================================================================
Purpose:
	-This report consolidates key product metrics and behaviors.

Highlight:
	1. Gathers essential fields such as product name, category, subcategory, and cost.
	2. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	3. Segment products by revenue to identify High-performers, Mid-range, or Low-performers
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
============================================================================================================
*/
CREATE VIEW gold.report_products AS
WITH base_query AS (
/*----------------------------------------------------------------------------------------------------------
1. Base Query: Retrieves core columns from table
----------------------------------------------------------------------------------------------------------*/
SELECT 
	f.order_number,
	f.customer_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key -- Only consider valid sales
WHERE order_date IS NOT NULL
)
, product_aggregations AS (
/*----------------------------------------------------------------------------------------------------------
2. Product Aggregations: Summarizes key metrics at the product level
----------------------------------------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity_sold,
	MAX(order_date) AS last_sale_date,
	EXTRACT(MONTH FROM AGE (MAX(order_date), MIN(order_date))) AS lifespan_in_months,
	ROUND(AVG((sales_amount::NUMERIC / NULLIF(quantity, 0))), 1) AS avg_selling_price
FROM base_query
GROUP BY 
	product_key,
	product_name,
	category,
	subcategory,
	cost
)

/*----------------------------------------------------------------------------------------------------------
3. Segmenting products by revenue to identify High-performers, Mid-range, or Low-performers
----------------------------------------------------------------------------------------------------------*/
SELECT 	
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	-- recency (months since last sale)
	EXTRACT(YEAR FROM AGE(NOW(), last_sale_date)) * 12 + 
	EXTRACT(MONTH FROM AGE(NOW(), last_sale_date)) AS recency_in_months,
	CASE 
		WHEN total_sales > 50000 THEN 'High-performer'
		WHEN total_sales >= 10000 THEN 'Mid-performer'
		ELSE 'Low-performer'
	END AS product_segment,
	lifespan_in_months,
	total_orders,
	total_customers,
	total_sales,
	total_quantity_sold,
	avg_selling_price,
	
	-- Average Order Revenue (AOR)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan_in_months = 0 THEN total_sales
		ELSE ROUND(total_sales / lifespan_in_months)
	END AS avg_monthly_revenue
FROM product_aggregations

/*----------------------------------------------------------------------------------------------------------
Key Insights
1. Revenue Concentration Risk:
A small number of high-performers (>$50k sales) likely drive the majority of revenue. Diversify portfolio to reduce dependency on a few products.
2. Portfolio Gaps:
A high number of low-performers (<$10k) waste resources. Consolidate underperformers or discontinue to focus on growth products.
3. Sales Momentum Matters:
Monitor recency (months since last sale). Products with high recency are losing momentum—need a relaunch or repositioning strategy.
4. Customer Reach vs. Revenue:
Compare total customers per product to total sales. Wide customer base but low revenue = pricing issue. Few customers, high revenue = premium positioning.
5. Category Performance
Identify best-performing categories. Allocate inventory budget proportionally and develop new products in high-demand categories.
Bottom Line: Focus resources on high-performers, consolidate low-performers, and reposition mid-range products for growth.
----------------------------------------------------------------------------------------------------------*/
