/* 
============================================================================================================
Customer Report
============================================================================================================
Purpose:
	-This report consolidates key customer metrics and behaviors.

Highlight:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	3. Segments customers into categories (VIP, Regular, New) and age groups.
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value (AOV)
		- average monthly spend
============================================================================================================
*/
CREATE VIEW gold.report_customers AS 
WITH base_query AS (
/*----------------------------------------------------------------------------------------------------------
1. Base Query: Retrieves core columns from table
----------------------------------------------------------------------------------------------------------*/
SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	EXTRACT(YEAR FROM AGE(NOW(), birthdate)) AS age
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL
)
, customer_aggregation AS (
/*----------------------------------------------------------------------------------------------------------
2. Customer Aggregations: Summarizes key metrics at the customer level
----------------------------------------------------------------------------------------------------------*/
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT product_key) AS total_products,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	MAX(order_date) AS last_order_date,
	EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 + 
	EXTRACT(MONTH FROM AGE(MIN(order_date))) AS lifespan_in_months
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
/*----------------------------------------------------------------------------------------------------------
3. Segmenting customers into categories (VIP, Regular, New) and age groups.
----------------------------------------------------------------------------------------------------------*/
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
		CASE
			WHEN age < 20 THEN 'Under 20'
			WHEN age BETWEEN 20 AND 29 THEN '20-29'
			WHEN age BETWEEN 30 AND 39 THEN '30-39'
			WHEN age BETWEEN 40 AND 49 THEN '40-49'
			ELSE '50 and above'
		END AS age_group,
		CASE
			WHEN lifespan_in_months >= 12 AND total_sales > 5000 THEN 'VIP'
			WHEN lifespan_in_months >= 12 AND total_sales <= 5000 THEN 'Regular'
			ELSE 'New'
		END AS customer_segments,
	last_order_date,
	EXTRACT(YEAR FROM AGE(NOW(), last_order_date)) * 12 + 
	EXTRACT(MONTH FROM AGE(NOW(), last_order_date)) AS recency_in_months,
	total_orders,
	total_products,
	total_sales,
	total_quantity,
	lifespan_in_months,
	--Compute average order value (AOV)
	CASE
		WHEN total_sales = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_value,
	--Compute average monthly spend
	CASE
		WHEN lifespan_in_months = 0 THEN total_sales
		ELSE ROUND(total_sales / lifespan_in_months)
	END AS avg_monthly_spend
FROM customer_aggregation

/*----------------------------------------------------------------------------------------------------------
Key Insights
1. Retention Challenge:
Only 20% of customers survive beyond 12 months, meaning the focus should be on improving early-stage customer stickiness.
2. Revenue Concentration:
9% VIPs (1,619 customers) likely drive 50%+ of revenue. Protecting VIP retention is critical.
3. Upsell Opportunity:
2,037 Regular customers have proven loyalty but aren't spending enough ($5k+). Target them for upsell campaigns to the VIP tier.
4. Conversion Funnel:
Current rate: 100 new customers → 20 survive 12 months → 9 become VIP. Improving this funnel is the highest ROI strategy.
Bottom Line: Build better retention in year 1, protect VIPs, and upsell Regular customers.
----------------------------------------------------------------------------------------------------------*/
