
-- #########################################################
--1. Total transactions and total quantity per payment method
-- ##########################################################
-- Purpose => Understand which payment methods are popular for transaction optimization.

SELECT 
    payment_method,
    COUNT(*) AS total_transactions,
    SUM(quantity) AS total_items_sold
FROM sales
GROUP BY payment_method
ORDER BY total_transactions DESC; 


-- ####################################
-- 2. Highest-Rated Category per Branch
-- ####################################
-- This allows Walmart to recognize and promote popular categories in specific
-- branches, enhancing customer satisfaction and branch-specific marketing.
WITH ranked_categories AS (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rn
    FROM sales
    GROUP BY branch, category
)
SELECT branch, category, avg_rating
FROM ranked_categories
WHERE rn = 1
ORDER BY branch;


-- ########################################################################
--3. busiest day of the week for each branch based on transaction volume
-- ########################################################################
-- Purpose: Optimize staffing and inventory on peak days.

-- SELECT * 
-- FROM
-- 	(SELECT 
-- 		branch,
-- 		TO_CHAR(date, 'Day') as day_name,
-- 		COUNT(*) as no_transactions,
-- 		RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
-- 	FROM sales
-- 	GROUP BY 1, 2
-- 	) AS ranked_days
-- WHERE rank = 1


--- Efficient approach

WITH daily_counts AS (
    SELECT
	   branch, 
       TRIM(TO_CHAR(date, 'Day')) AS day_name,	
	   COUNT(*) AS no_transactions
	FROM sales
	GROUP BY branch, day_name
), 

ranked_days AS (

	  SELECT
        branch,
        day_name,
        no_transactions,
		RANK() OVER(
           PARTITION BY branch
		   ORDER BY no_transactions DESC
		) AS rnk

	FROM daily_counts
) 

SELECT
    branch,
    day_name,
    no_transactions
FROM ranked_days
WHERE rnk = 1
ORDER BY branch;



--- 4. Calculate Total Quantity Sold by Payment Method

SELECT payment_method, SUM(quantity) AS total_items_sold
FROM sales
GROUP BY payment_method
ORDER BY total_items_sold DESC;


-- Purpose:5.  Guide city-level promotions and tailor regional strategies.

SELECT city, category,
       AVG(rating) AS avg_rating,
       MIN(rating) AS min_rating,
       MAX(rating) AS max_rating
FROM sales
GROUP BY city, category
ORDER BY city, category;


-- 6. Calculate Total Profit by Category
-- Purpose: Identify high-profit categories for pricing and promotion strategies.

SELECT category,
       SUM(unit_price * quantity * profit_margin) AS total_profit
FROM sales
GROUP BY category
ORDER BY total_profit DESC;



-- 7. Determine the Most Common Payment Method per Branch
-- Purpose: Streamline branch-specific payment processing.

SELECT * FROM
 (
  SELECT branch,
  payment_method,
  COUNT(*) as no_transactions,
  RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
 FROM sales
 GROUP BY 1, 2
  )AS ranked_payment
WHERE rank = 1;



-- ########################################################################
-- 8. Categorize sales into 3 group MORNING, AFTERNOON, EVENING 
-- Find out each of the shift and number of invoices
-- ########################################################################


-- SELECT branch,
--    CASE
--       WHEN TO_CHAR(TO_TIMESTAMP(time, 'HH24:MI:SS'), 'HH24')::int BETWEEN 6 AND 11 THEN 'Morning'
-- 	  WHEN TO_CHAR(TO_TIMESTAMP(time, 'HH24:MI:SS'), 'HH24')::int BETWEEN 12 AND 17 THEN 'Afternoon'
--       ELSE 'Evening'
--    END AS shift,
--    COUNT(*) AS total_transactions

--   FROM sales
-- GROUP BY branch, shift
-- ORDER BY branch, shift;


SELECT
	branch,
CASE 
		WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END shift,
	COUNT(*)
FROM sales
GROUP BY 1, 2
ORDER BY 1, 3 DESC;



-- ########################################################################
-- 9. Identify 5 branch with highest decrese ratio in 
-- revevenue compare to last year(current year 2023 and last year 2022)

-- rdr == last_rev-cr_rev/ls_rev*100

-- ########################################################################
WITH revenue_per_year AS (
   SELECT
       branch,
       EXTRACT(YEAR FROM date) AS year,
       SUM(total) AS total_revenue
   FROM sales
   GROUP BY branch, year
)

SELECT
    a.branch,
    a.year AS current_year,
    a.total_revenue AS current_revenue,
    b.total_revenue AS previous_revenue,
   ROUND(
     (
    (b.total_revenue - a.total_revenue)
        / NULLIF(b.total_revenue, 0)
       )::numeric * 100,
  2
) AS revenue_decline_pct

FROM revenue_per_year a
JOIN revenue_per_year b
  ON a.branch = b.branch
 AND a.year = b.year + 1
WHERE a.total_revenue < b.total_revenue
ORDER BY current_year, revenue_decline_pct DESC;