SELECT *
FROM sales;

-- create a staging table
CREATE TABLE sales_staging
LIKE sales;

INSERT INTO sales_staging
SELECT *
FROM sales;

SELECT *
FROM sales_staging;

-- standardize column names
ALTER TABLE sales_staging
CHANGE COLUMN ï»¿transaction_id transaction_id INT;

-- Converting string date/time to date/time format to facilitate datetime operations
UPDATE sales_staging
SET transaction_date = STR_TO_DATE(transaction_date, '%d-%m-%Y');

ALTER TABLE sales_staging
MODIFY COLUMN transaction_date DATE;

UPDATE sales_staging
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

ALTER TABLE sales_staging
MODIFY COLUMN transaction_time TIME;

-- scope of data
SELECT
	MIN(transaction_date) as min_date,
    MAX(transaction_date) as max_date
FROM
	sales_staging;

-- Total Sales Analysis
SELECT 
	MONTH(transaction_date) as `month`, 
	ROUND(SUM(unit_price * transaction_qty),2) AS total_sales
FROM sales_staging
GROUP BY MONTH(transaction_date)
ORDER BY 2 DESC;

-- Checking the month-on-month change in sales. 
SELECT
	MONTH(transaction_date) AS `month`,
    ROUND(sum(unit_price * transaction_qty),2) AS total_sales,
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty),1) OVER(ORDER BY MONTH(transaction_date)))/
    LAG(SUM(unit_price * transaction_qty),1) OVER(ORDER BY MONTH(transaction_date)) *100 AS mom_change_percentage
FROM
	sales_staging
GROUP BY `month`;

-- Total Order Analysis; per month
SELECT
	MONTH(transaction_date) AS `month`,
	COUNT(transaction_id) AS total_orders
FROM sales_staging
GROUP BY MONTH(transaction_date);

-- Checking the month-on-month change in order quantity
SELECT
	MONTH(transaction_date) AS `month`,
    COUNT(transaction_id) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id),1) OVER(ORDER BY MONTH(transaction_date)))/
    LAG(COUNT(transaction_id),1) OVER(ORDER BY MONTH(transaction_date)) * 100 AS mom_change_percentage
FROM
	sales_staging
GROUP BY `month`;

-- Total Quantity Analysis; per month
SELECT 
	MONTH(transaction_date) as `month`, 
	SUM(transaction_qty) AS total_qty_sold
FROM sales_staging
GROUP BY MONTH(transaction_date)
ORDER BY 2 DESC;

-- Checking the month-on-month change in transaction quantity
SELECT
	MONTH(transaction_date) AS `month`,
    ROUND(sum(transaction_qty),2) AS total_quantity,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty),1) OVER(ORDER BY MONTH(transaction_date)))/
    LAG(SUM(transaction_qty),1) OVER(ORDER BY MONTH(transaction_date)) *100 AS mom_change_percentage
FROM
	sales_staging
GROUP BY `month`;

-- checking the sales, orders and quantity on a day-to-day basis
SELECT
	DAYNAME(transaction_date) as `day`,
    MONTH(transaction_date) AS `month`,
	ROUND(sum(unit_price * transaction_qty),2) AS total_sales,
    SUM(transaction_qty) AS total_qty_sold,
    COUNT(transaction_id) AS total_orders
FROM 
	sales_staging
GROUP BY DAYNAME(transaction_date), `month`;

-- sales trends on weekdays and weekends
SELECT
	MONTH(transaction_date) AS `month`,
	CASE 
		WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'Weekends'
		ELSE 'Weekdays'
    END AS day_type,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_sales
FROM sales_staging
GROUP BY 
	MONTH(transaction_date),
    day_type;
    
-- sales analysis by store location
SELECT
	store_location,
    MONTH(transaction_date) AS `month`,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_sales
FROM
	sales_staging
GROUP BY MONTH(transaction_date), store_location;

-- sales analysis by product category
SELECT
	product_category,
    MONTH(transaction_date) AS `month`,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_sales
FROM
	sales_staging
GROUP BY `month`, product_category
ORDER BY `month` ASC, total_sales DESC;

/* Top 10 products by sales
	If we want a month-wise report, we have to groupby month like in the above query */
SELECT
	product_type,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_sales
FROM
	sales_staging
GROUP BY product_type
ORDER BY total_sales DESC
LIMIT 10;

-- daily sales compared with average sales for the month
WITH sales_comparison AS (
	SELECT
		MONTH(transaction_Date) AS `month`,
		DAY(transaction_date) AS day_of_month,
        ROUND(SUM(unit_price * transaction_qty), 2) as total_sales,
        ROUND(AVG(SUM(unit_price * transaction_qty)) OVER(PARTITION BY MONTH(transaction_date)), 2) as avg_sales
	FROM
		sales_staging
	GROUP BY day_of_month, `month`
)
SELECT
	`month`,
    day_of_month,
    CASE
		WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status
FROM sales_comparison;

-- Sales analysis by Days and Hours
SELECT
	MONTH(transaction_date) AS `month`,
    DAYOFWEEK(transaction_date) AS day_of_week,
    HOUR(transaction_time) AS `hour`,
	ROUND(SUM(unit_price * transaction_qty), 2) AS total_Sales,
    SUM(transaction_qty) AS total_qty_sold,
    COUNT(*) AS total_orders
FROM
	sales_staging
GROUP BY `month`, day_of_week, `hour`
ORDER BY 'hour';
















