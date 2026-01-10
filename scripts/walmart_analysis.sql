
-- #########################################################
-- Total transactions and total quantity per payment method
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
--  Highest-Rated Category per Branch
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
-- busiest day of the week for each branch based on transaction volume
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



--- Calculate Total Quantity Sold by Payment Method

SELECT payment_method, SUM(quantity) AS total_items_sold
FROM sales
GROUP BY payment_method
ORDER BY total_items_sold DESC;


-- Purpose: Guide city-level promotions and tailor regional strategies.

SELECT city, category,
       AVG(rating) AS avg_rating,
       MIN(rating) AS min_rating,
       MAX(rating) AS max_rating
FROM sales
GROUP BY city, category
ORDER BY city, category;


-- Calculate Total Profit by Category
-- Purpose: Identify high-profit categories for pricing and promotion strategies.

SELECT category,
       SUM(unit_price * quantity * profit_margin) AS total_profit
FROM sales
GROUP BY category
ORDER BY total_profit DESC;



-- Determine the Most Common Payment Method per Branch
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
WHERE rank = 1