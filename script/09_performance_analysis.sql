/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
	- LEAD(): Accesses data from next rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */
WITH yearly_product_sales AS (
SELECT
	EXTRACT(YEAR FROM f.order_date) AS order_year,
	p.product_name,
	SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM f.order_date), p.product_name
)
SELECT 
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
	current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name)) AS avg_diff,
	CASE
		WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name)) > 0 THEN 'Above Avg'
		WHEN current_sales - ROUND(AVG(current_sales) OVER (PARTITION BY product_name)) < 0 THEN 'Below Avg'
		ELSE 'Avg'
	END AS avg_change,
	LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
	current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_diff,
	CASE 
		WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
		ELSE 'No change'
	END AS py_change,
	LEAD(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS next_year_sales,
	LEAD(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) - current_sales AS ny_diff,
	CASE 
		WHEN LEAD(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
		WHEN LEAD(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) - current_sales < 0 THEN 'Decrease'
		ELSE 'No change'
	END AS ny_change
FROM yearly_product_sales
ORDER BY product_name, order_year
