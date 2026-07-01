/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/

-- Determine the first and last order date and the total duration in months
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) AS order_range_year,
	  EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
	  EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS total_months
FROM gold.fact_sales
WHERE order_date IS NOT NULL;


-- Find the youngest and oldest customers based on birthdate
SELECT
    MIN(birthdate) AS oldest_birthdate,
  	EXTRACT(YEAR FROM AGE(NOW(), MIN(birthdate))) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    EXTRACT(YEAR FROM AGE(NOW(), MAX(birthdate))) AS youngest_age
FROM gold.dim_customers;
