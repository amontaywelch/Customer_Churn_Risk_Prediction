-- Churn Analysis: Exploratory SQL Queries
-- This script explores behavioral patterns associated with customer churn.
-- The analysis covers churn rates, engagement, purchasing behavior, support interactions, and high-risk customer segments to support retention strategy development.


-- Initial Data Preview
-- View the first 10 rows of the customer_info table to understand its structure and sample values
SELECT *
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
LIMIT 10;


-- churn distribution
SELECT churn, COUNT(*) AS customer_count
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY churn;


-- churn, customer distribution by gender
SELECT gender, churn, COUNT(customer_id) AS customer_count
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY gender, churn
ORDER BY customer_count DESC;


-- Analyze average behavior by churn status:
-- - Total spend
-- - Engagement score
-- - App opens in the last 30 days
-- This helps compare how retained vs. churned customers differ in key usage metrics
SELECT churn, 
       ROUND(AVG(total_spend), 2) AS avg_spend,
       ROUND(AVG(engagement_score), 2) AS avg_engagement,
       ROUND(AVG(app_opens_last_30d), 2) AS avg_app_opens
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY churn;



-- Group customers into recency buckets based on days since last purchase
-- Then calculate:
-- - Total customers in each bucket
-- - Number of churned customers
-- - Churn rate per group
-- This helps identify how purchase recency correlates with churn risk.
SELECT 
  CASE 
    WHEN time_since_last_purchase <= 30 THEN '0–30 days'
    WHEN time_since_last_purchase <= 60 THEN '31–60 days'
    ELSE '60+ days'
  END AS recency_bucket,
  COUNT(customer_id) AS customer_count,
  SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
  ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY recency_bucket
ORDER BY churn_rate DESC;


-- Analyze churn rate by signup year cohort.
-- Uses `signup_days_ago` to estimate signup year.
-- Shows:
-- - Total number of customers per signup year
-- - Number of churned customers
-- - Churn rate per year
-- Helps identify if newer cohorts are churning faster or if older users are more loyal.
SELECT 
  EXTRACT(YEAR FROM DATE_SUB(CURRENT_DATE(), INTERVAL signup_days_ago DAY)) AS signup_year,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
  ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY signup_year
ORDER BY signup_year;


-- Identify cities with the highest number of churned customers.
-- Filters only churned records and counts how many churned in each city.
-- Helps prioritize regional retention strategies or marketing efforts.
SELECT city, COUNT(*) AS churned_customers
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
WHERE churn = 1
GROUP BY city
ORDER BY churned_customers DESC
LIMIT 5;


-- Identify high-risk customer segments by device type and most frequent product category
-- Calculates:
--   - Total customers in each segment
--   - Number and rate of churned customers
-- Filters to segments with more than 50 customers to ensure meaningful sample sizes
-- Useful for targeting retention strategies by behavior and platform preference
SELECT device_type, most_frequent_category,
       COUNT(*) AS total_customers,
       SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
       ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY device_type, most_frequent_category
HAVING COUNT(*) > 50
ORDER BY churn_rate DESC
LIMIT 10;


-- Compare behavioral averages between churned and retained customers
-- Calculates average values for:
--   - Total spend
--   - App opens in the last 30 days
--   - Email open rate
--   - Customer support calls
-- Helps identify which behaviors differentiate churned users from retained ones
SELECT churn,
       ROUND(AVG(total_spend), 2) AS avg_spend,
       ROUND(AVG(app_opens_last_30d), 2) AS avg_app_opens,
       ROUND(AVG(email_open_rate), 2) AS avg_email_open,
       ROUND(AVG(customer_support_calls), 2) AS avg_support_calls
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY churn;


-- Correlation analysis between key behavioral metrics and churn
-- Measures linear relationships using Pearson correlation:
--   - engagement_score vs. total_spend: are more engaged customers spending more?
--   - purchase_frequency vs. app_opens_last_30d: do frequent buyers also engage more with the app?
--   - email_open_rate vs. churn: is email engagement negatively correlated with churn?
-- Helps uncover which features are strongly related and may be predictive in modeling
SELECT 
  CORR(engagement_score, total_spend) AS corr_engagement_spend,
  CORR(purchase_frequency, app_opens_last_30d) AS corr_freq_app_opens,
  CORR(email_open_rate, churn) AS corr_email_churn
FROM `cryptic-dahlia-453622-m9.churn.customer_info`;


-- Churn by device and age band
SELECT device_type, 
       CASE 
         WHEN age < 25 THEN '<25'
         WHEN age BETWEEN 25 AND 40 THEN '25–40'
         ELSE '40+'
       END AS age_group,
       COUNT(*) AS total,
       SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
       ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY device_type, age_group
ORDER BY churn_rate DESC;


-- Churn by engagement recency
SELECT 
  CASE 
    WHEN time_since_last_purchase < 15 THEN '0–14 days'
    WHEN time_since_last_purchase < 45 THEN '15–44 days'
    ELSE '45+ days'
  END AS recency_group,
  COUNT(*) AS customers,
  SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
  ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY recency_group
ORDER BY churn_rate DESC;


-- Cross-check app usage and email engagement with churn
SELECT 
  CASE 
    WHEN app_opens_last_30d < 5 THEN 'Low App Usage'
    ELSE 'Active App User'
  END AS app_user_status,
  CASE 
    WHEN email_open_rate < 0.3 THEN 'Low Email Engagement'
    ELSE 'High Email Engagement'
  END AS email_group,
  COUNT(*) AS customers,
  SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
  ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY app_user_status, email_group
ORDER BY churn_rate DESC;


-- High spenders with low engagement
SELECT customer_id, total_spend, engagement_score, churn
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
WHERE total_spend > 500 
  AND engagement_score < 40
ORDER BY total_spend DESC
LIMIT 15;


-- Analyze churn by preferred time of day for purchases
-- Helps identify if churn risk varies by when customers prefer to shop
SELECT preferred_purchase_time,
       COUNT(*) AS customers,
       SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
       ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY preferred_purchase_time
ORDER BY churn_rate DESC;


-- Segment churn rates by discount usage patterns
-- Helps evaluate if discount-heavy users are less loyal or price-sensitive
SELECT 
  CASE 
    WHEN discount_usage_rate < 0.2 THEN 'Low (<20%)'
    WHEN discount_usage_rate < 0.5 THEN 'Moderate (20–49%)'
    ELSE 'High (50%+)'
  END AS discount_group,
  COUNT(*) AS customers,
  SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
  ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY discount_group
ORDER BY churn_rate DESC;


-- Analyze how churn correlates with support interactions
-- High call frequency may signal dissatisfaction or service issues
SELECT customer_support_calls,
       COUNT(*) AS customers,
       SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) AS churned,
       ROUND(SUM(CASE WHEN churn = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM `cryptic-dahlia-453622-m9.churn.customer_info`
GROUP BY customer_support_calls
HAVING customer_support_calls IS NOT NULL
ORDER BY customer_support_calls;


-- adding signup_date for time series visuals in Power BI
CREATE OR REPLACE TABLE `cryptic-dahlia-453622-m9.churn.customer_info` AS
SELECT *,
  DATE_SUB(CURRENT_DATE(), INTERVAL signup_days_ago DAY) AS signup_date
FROM `cryptic-dahlia-453622-m9.churn.customer_info`;




-- End of exploratory churn analysis
-- This analysis provides a foundation for identifying high-risk customer segments, 
-- early warning signals, and behavior patterns to support targeted retention strategies.