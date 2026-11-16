-- Combined from 07_Basic_Analysis.sql
USE smart_delivery_analytics;

-- Q01 Platform order status mix
SELECT status,
  COUNT(*) order_count,
  ROUND(100*COUNT(*)/(
    SELECT COUNT(*)
    FROM orders),2) pct
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Q02 Cities served
SELECT DISTINCT city
FROM customers
ORDER BY city;

-- Q03 Customer coverage by city
SELECT city,
  COUNT(*) customers
FROM customers
GROUP BY city
ORDER BY customers DESC;

-- Q04 Restaurant coverage by cuisine
SELECT cuisine_type,
  COUNT(*) restaurants
FROM restaurants
GROUP BY cuisine_type
ORDER BY restaurants DESC;

-- Q05 Fleet composition
SELECT vehicle_type,
  COUNT(*) partners
FROM delivery_partners
GROUP BY vehicle_type
ORDER BY partners DESC;

-- Q06 Basket amount summary
SELECT MIN(order_amount) min_basket,
  MAX(order_amount) max_basket,
  ROUND(AVG(order_amount),2) avg_basket
FROM orders;

-- Q07 Delivered duration summary in minutes
SELECT ROUND(AVG(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60,2) avg_min,
  MIN(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60 min_min,
  MAX(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60 max_min
FROM orders
WHERE status='Delivered';

-- Q08 Delivered item GMV by restaurant city (not company net revenue)
SELECT r.city,
  ROUND(SUM(o.order_amount),2) delivered_item_gmv
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.city
ORDER BY delivered_item_gmv DESC;

-- Q09 Payment modes by count and captured amount; payment status/refund fields are absent
SELECT payment_mode,
  COUNT(*) transactions,
  ROUND(SUM(amount),2) amount_total
FROM payments
GROUP BY payment_mode
ORDER BY transactions DESC;

-- Q10 Customer rating distribution
SELECT customer_rating,
  COUNT(*) rating_count
FROM ratings
GROUP BY customer_rating
ORDER BY customer_rating;

-- Q11 Restaurant rating extremes
SELECT MIN(rating) min_rating,
  MAX(rating) max_rating,
  ROUND(AVG(rating),2) avg_rating
FROM restaurants;

-- Q12 Ten largest basket amounts
SELECT order_id,
  order_amount,
  status
FROM orders
ORDER BY order_amount DESC
LIMIT 10;

-- Q13 Top rated restaurants
SELECT restaurant_id,
  restaurant_name,
  rating
FROM restaurants
ORDER BY rating DESC,
  restaurant_id
LIMIT 10;

-- Q14 Customers with more than five source orders
SELECT customer_id,
  COUNT(*) order_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*)>5
ORDER BY order_count DESC,
  customer_id
LIMIT 20;

-- Q15 Orders by calendar month
SELECT DATE_FORMAT(order_time,'%Y-%m') order_month,
  COUNT(*) orders
FROM orders
GROUP BY order_month
ORDER BY order_month;


-- Combined from 08_Intermediate_Analysis.sql
USE smart_delivery_analytics;

-- Q16 Restaurants with longest average delivered duration; at least 20 deliveries
SELECT r.restaurant_id,
  r.restaurant_name,
  COUNT(*) deliveries,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60,2) avg_minutes
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.restaurant_id,
  r.restaurant_name
HAVING COUNT(*)>=20
ORDER BY avg_minutes DESC
LIMIT 15;

-- Q17 Partners with longest average delivered duration; at least 20 deliveries
SELECT d.partner_id,
  d.partner_name,
  COUNT(*) deliveries,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60,2) avg_minutes
FROM orders o
JOIN delivery_partners d USING(partner_id)
WHERE o.status='Delivered'
GROUP BY d.partner_id,
  d.partner_name
HAVING COUNT(*)>=20
ORDER BY avg_minutes DESC
LIMIT 15;

-- Q18 Average delivery duration by restaurant operating city
SELECT r.city,
  COUNT(*) deliveries,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60,2) avg_minutes
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.city
ORDER BY avg_minutes DESC;

-- Q19 Month-to-month mean delivered duration (descriptive, not SLA lateness)
SELECT DATE_FORMAT(order_time,'%Y-%m') order_month,
  COUNT(*) delivered,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60,2) avg_minutes
FROM orders
WHERE status='Delivered'
GROUP BY order_month
ORDER BY order_month;

-- Q20 Restaurant delivery duration variability; at least 20 delivered orders
SELECT r.restaurant_id,
  r.restaurant_name,
  COUNT(*) n,
  ROUND(STDDEV_SAMP(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time)/60),2) sd_minutes
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.restaurant_id,
  r.restaurant_name
HAVING COUNT(*)>=20
ORDER BY sd_minutes DESC
LIMIT 15;

-- Q21 Best average-duration partner within each city, city defined by restaurant location
WITH partner_city AS (
  SELECT r.city,d.partner_id,d.partner_name,COUNT(*) deliveries,AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60 avg_minutes
  FROM orders o
  JOIN restaurants r USING(restaurant_id)
  JOIN delivery_partners d USING(partner_id)
  WHERE o.status='Delivered'
  GROUP BY r.city,d.partner_id,d.partner_name
  HAVING COUNT(*)>=10),
  ranked AS (
  SELECT *,ROW_NUMBER() OVER(PARTITION BY city
    ORDER BY avg_minutes,deliveries DESC) rn
  FROM partner_city)
SELECT city,
  partner_id,
  partner_name,
  deliveries,
  ROUND(avg_minutes,2) avg_minutes
FROM ranked
WHERE rn=1
ORDER BY city;

-- Q22 Delivery duration by weekday
SELECT DAYNAME(order_time) weekday,
  DAYOFWEEK(order_time) weekday_num,
  COUNT(*) deliveries,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60,2) avg_minutes
FROM orders
WHERE status='Delivered'
GROUP BY weekday,
  weekday_num
ORDER BY avg_minutes DESC;

-- Q23 Share of delivered orders taking more than 45 minutes (threshold is a descriptive cut, not an SLA)
SELECT COUNT(*) delivered,
  SUM(TIMESTAMPDIFF(SECOND,order_time,delivered_time)>2700) over_45,
  ROUND(100*SUM(TIMESTAMPDIFF(SECOND,order_time,delivered_time)>2700)/COUNT(*),2) pct_over_45
FROM orders
WHERE status='Delivered';

-- Q24 Duration by cuisine
SELECT r.cuisine_type,
  COUNT(*) deliveries,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60,2) avg_minutes
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.cuisine_type
ORDER BY avg_minutes DESC;

-- Q25 Cancellations by restaurant volume
SELECT r.restaurant_id,
  r.restaurant_name,
  COUNT(*) cancellations
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Cancelled'
GROUP BY r.restaurant_id,
  r.restaurant_name
ORDER BY cancellations DESC
LIMIT 15;

-- Q26 City cancellation rate (restaurant operating city)
SELECT r.city,
  COUNT(*) orders_total,
  SUM(o.status='Cancelled') cancelled,
  ROUND(100*SUM(o.status='Cancelled')/COUNT(*),2) cancellation_pct
FROM orders o
JOIN restaurants r USING(restaurant_id)
GROUP BY r.city
ORDER BY cancellation_pct DESC;

-- Q27 Cancellation share by last recorded delivery duration bucket; cancellations have no duration
SELECT CASE WHEN status='Cancelled' THEN 'Cancelled (duration unavailable)' WHEN status='Pending' THEN 'Pending (duration unavailable)' WHEN TIMESTAMPDIFF(MINUTE,order_time,delivered_time)<=30 THEN 'Delivered <=30m' WHEN TIMESTAMPDIFF(MINUTE,order_time,delivered_time)<=45 THEN 'Delivered 31-45m' ELSE 'Delivered >45m' END duration_status,
  COUNT(*) orders,
  SUM(status='Cancelled') cancellations
FROM orders
GROUP BY duration_status
ORDER BY orders DESC;

-- Q28 Cancellation peaks by weekday and hour
SELECT DAYNAME(order_time) weekday,
  HOUR(order_time) order_hour,
  COUNT(*) cancellations
FROM orders
WHERE status='Cancelled'
GROUP BY weekday,
  order_hour
ORDER BY cancellations DESC
LIMIT 15;

-- Q29 Restaurants above overall cancellation rate (rate calculated on all orders)
WITH overall AS (
  SELECT AVG(status='Cancelled') rate
  FROM orders),
  by_restaurant AS (
  SELECT restaurant_id,COUNT(*) n,SUM(status='Cancelled')/COUNT(*) rate
  FROM orders
  GROUP BY restaurant_id)
SELECT r.restaurant_id,
  r.restaurant_name,
  b.n,
  ROUND(100*b.rate,2) cancellation_pct,
  ROUND(100*o.rate,2) overall_pct
FROM by_restaurant b
JOIN restaurants r USING(restaurant_id)
CROSS JOIN overall o
WHERE b.rate>o.rate
ORDER BY b.rate DESC;

-- Q30 Cancellation share by order hour
SELECT HOUR(order_time) order_hour,
  COUNT(*) all_orders,
  SUM(status='Cancelled') cancelled,
  ROUND(100*SUM(status='Cancelled')/COUNT(*),2) cancellation_pct
FROM orders
GROUP BY order_hour
ORDER BY order_hour;

-- Q31 Monthly cancellations and rate
SELECT DATE_FORMAT(order_time,'%Y-%m') order_month,
  COUNT(*) total_orders,
  SUM(status='Cancelled') cancelled,
  ROUND(100*SUM(status='Cancelled')/COUNT(*),2) cancellation_pct
FROM orders
GROUP BY order_month
ORDER BY order_month;

-- Q32 Partner associated cancellation rates; association does not establish cause
SELECT d.partner_id,
  d.partner_name,
  COUNT(*) assigned_orders,
  SUM(o.status='Cancelled') cancellations,
  ROUND(100*SUM(o.status='Cancelled')/COUNT(*),2) cancellation_pct
FROM orders o
JOIN delivery_partners d USING(partner_id)
GROUP BY d.partner_id,
  d.partner_name
HAVING COUNT(*)>=20
ORDER BY cancellation_pct DESC
LIMIT 15;

-- Q33 Pending order percentage
SELECT COUNT(*) orders_total,
  SUM(status='Pending') pending,
  ROUND(100*SUM(status='Pending')/COUNT(*),2) pending_pct
FROM orders;

-- Q34 Restaurant gross delivered item value
SELECT r.restaurant_id,
  r.restaurant_name,
  ROUND(SUM(o.order_amount),2) delivered_item_gmv,
  COUNT(*) delivered_orders
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.restaurant_id,
  r.restaurant_name
ORDER BY delivered_item_gmv DESC
LIMIT 15;

-- Q35 Customer order frequency and average delivered basket
SELECT c.customer_id,
  c.customer_name,
  COUNT(*) delivered_orders,
  ROUND(AVG(o.order_amount),2) avg_delivered_basket
FROM orders o
JOIN customers c USING(customer_id)
WHERE o.status='Delivered'
GROUP BY c.customer_id,
  c.customer_name
ORDER BY delivered_orders DESC
LIMIT 20;


-- Combined from 09_Advanced_Analysis.sql
USE smart_delivery_analytics;

-- Q36 City delivered item GMV rank
WITH city_gmv AS (
  SELECT r.city,SUM(o.order_amount) gmv
  FROM orders o
  JOIN restaurants r USING(restaurant_id)
  WHERE o.status='Delivered'
  GROUP BY r.city)
SELECT city,
  ROUND(gmv,2) delivered_item_gmv,
  DENSE_RANK() OVER(
  ORDER BY gmv DESC) city_rank
FROM city_gmv
ORDER BY city_rank;

-- Q37 Monthly delivered item GMV and MoM growth
WITH monthly AS (
  SELECT DATE_FORMAT(order_time,'%Y-%m') month,SUM(order_amount) gmv
  FROM orders
  WHERE status='Delivered'
  GROUP BY DATE_FORMAT(order_time,'%Y-%m')),
  compare_month AS (
  SELECT month,gmv,LAG(gmv) OVER(
    ORDER BY month) prior_gmv
  FROM monthly)
SELECT month,
  ROUND(gmv,2) delivered_item_gmv,
  ROUND(prior_gmv,2) prior_month_gmv,
  ROUND(100*(gmv-prior_gmv)/NULLIF(prior_gmv,0),2) mom_pct
FROM compare_month
ORDER BY month;

-- Q38 Top 10 customers by observed delivered order item spending
WITH spend AS (
  SELECT c.customer_id,c.customer_name,SUM(o.order_amount) spend,COUNT(*) delivered_orders
  FROM orders o
  JOIN customers c USING(customer_id)
  WHERE o.status='Delivered'
  GROUP BY c.customer_id,c.customer_name),
  ranked AS (
  SELECT *,ROW_NUMBER() OVER(
    ORDER BY spend DESC) rn
  FROM spend)
SELECT customer_id,
  customer_name,
  ROUND(spend,2) delivered_item_spend,
  delivered_orders
FROM ranked
WHERE rn<=10
ORDER BY rn;

-- Q39 Running monthly order count
WITH monthly AS (
  SELECT DATE_FORMAT(order_time,'%Y-%m') month,COUNT(*) n
  FROM orders
  GROUP BY DATE_FORMAT(order_time,'%Y-%m'))
SELECT month,
  n,
  SUM(n) OVER(
  ORDER BY month ROWS UNBOUNDED PRECEDING) running_orders
FROM monthly
ORDER BY month;

-- Q40 Rank delivery partners within restaurant operating city
WITH pc AS (
  SELECT r.city,d.partner_id,d.partner_name,COUNT(*) deliveries,AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60 avg_min
  FROM orders o
  JOIN restaurants r USING(restaurant_id)
  JOIN delivery_partners d USING(partner_id)
  WHERE o.status='Delivered'
  GROUP BY r.city,d.partner_id,d.partner_name
  HAVING COUNT(*)>=10)
SELECT city,
  partner_id,
  partner_name,
  deliveries,
  ROUND(avg_min,2) avg_min,
  RANK() OVER(PARTITION BY city
  ORDER BY avg_min) speed_rank
FROM pc
ORDER BY city,
  speed_rank;

-- Q41 Partner monthly duration changes using LAG
WITH pm AS (
  SELECT partner_id,DATE_FORMAT(order_time,'%Y-%m') month,AVG(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60 avg_min,COUNT(*) n
  FROM orders
  WHERE status='Delivered'
  GROUP BY partner_id,DATE_FORMAT(order_time,'%Y-%m')
  HAVING COUNT(*)>=5),
  changes AS (
  SELECT *,LAG(avg_min) OVER(PARTITION BY partner_id
    ORDER BY month) prior_min
  FROM pm)
SELECT partner_id,
  month,
  n,
  ROUND(avg_min,2) avg_min,
  ROUND(prior_min,2) prior_min,
  ROUND(avg_min-prior_min,2) change_minutes
FROM changes
WHERE prior_min IS NOT NULL
ORDER BY change_minutes
LIMIT 30;

-- Q42 Monthly partner speed top-10 persistence count
WITH pm AS (
  SELECT partner_id,DATE_FORMAT(order_time,'%Y-%m') month,AVG(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60 avg_min,COUNT(*) n
  FROM orders
  WHERE status='Delivered'
  GROUP BY partner_id,DATE_FORMAT(order_time,'%Y-%m')
  HAVING COUNT(*)>=5),
  ranked AS (
  SELECT *,ROW_NUMBER() OVER(PARTITION BY month
    ORDER BY avg_min) rn
  FROM pm)
SELECT partner_id,
  COUNT(*) months_eligible,
  SUM(rn<=10) top10_months
FROM ranked
GROUP BY partner_id
ORDER BY top10_months DESC,
  months_eligible DESC
LIMIT 20;

-- Q43 Restaurant duration variability rank
WITH rt AS (
  SELECT restaurant_id,AVG(TIMESTAMPDIFF(SECOND,order_time,delivered_time))/60 avg_min,STDDEV_SAMP(TIMESTAMPDIFF(SECOND,order_time,delivered_time)/60) sd_min,COUNT(*) n
  FROM orders
  WHERE status='Delivered'
  GROUP BY restaurant_id
  HAVING COUNT(*)>=20)
SELECT r.restaurant_name,
  rt.n,
  ROUND(rt.avg_min,2) avg_min,
  ROUND(rt.sd_min,2) sd_min,
  RANK() OVER(
  ORDER BY rt.sd_min DESC) variability_rank
FROM rt
JOIN restaurants r USING(restaurant_id)
ORDER BY variability_rank
LIMIT 15;

-- Q44 Signup month behavior summary; source churn snapshot is January 2025 per specification
SELECT DATE_FORMAT(c.signup_date,'%Y-%m') signup_month,
  COUNT(*) customers,
  ROUND(AVG(b.churn_flag)*100,2) churn_flag_pct,
  ROUND(AVG(b.total_orders),2) reported_avg_orders
FROM customers c
JOIN customer_behavior b USING(customer_id)
GROUP BY signup_month
ORDER BY signup_month;

-- Q45 City customer inactivity based on behavior snapshot and Jan 2025 reference date
SELECT c.city,
  COUNT(*) customers,
  SUM(b.last_order_days>90) inactive_over_90,
  ROUND(100*SUM(b.last_order_days>90)/COUNT(*),2) pct_inactive
FROM customers c
JOIN customer_behavior b USING(customer_id)
GROUP BY c.city
ORDER BY pct_inactive DESC;

-- Q46 Single-order customers based on orders.csv observed scope
WITH counts AS (
  SELECT customer_id,COUNT(*) n
  FROM orders
  GROUP BY customer_id)
SELECT COUNT(*) one_order_customers
FROM counts
WHERE n=1;

-- Q47 Repeat customer percentage based on observed orders.csv scope
WITH counts AS (
  SELECT customer_id,COUNT(*) n
  FROM orders
  GROUP BY customer_id)
SELECT COUNT(*) customers_with_orders,
  SUM(n>1) repeat_customers,
  ROUND(100*SUM(n>1)/COUNT(*),2) repeat_pct
FROM counts;

-- Q48 Segment spending using behavior mart, not order recomputation
SELECT CASE WHEN churn_flag=1 THEN 'Churn flagged' WHEN total_spending>=10000 THEN 'Active high spend' ELSE 'Active other' END segment,
  COUNT(*) customers,
  ROUND(AVG(total_spending),2) avg_reported_spend,
  ROUND(SUM(total_spending),2) segment_reported_spend
FROM customer_behavior
GROUP BY segment
ORDER BY segment_reported_spend DESC;

-- Q49 Summary-vs-fact order count reconciliation by customer
WITH fact AS (
  SELECT customer_id,COUNT(*) fact_orders
  FROM orders
  GROUP BY customer_id)
SELECT COUNT(*) customers,
  SUM(COALESCE(f.fact_orders,0)<>b.total_orders) mismatched_customers
FROM customer_behavior b
LEFT JOIN fact f USING(customer_id);

-- Q50 Delivered-order rating and duration association; descriptive grouped comparison only
SELECT CASE WHEN TIMESTAMPDIFF(MINUTE,o.order_time,o.delivered_time)<=30 THEN '<=30 min' WHEN TIMESTAMPDIFF(MINUTE,o.order_time,o.delivered_time)<=45 THEN '31-45 min' ELSE '>45 min' END duration_band,
  COUNT(*) rated_deliveries,
  ROUND(AVG(r.customer_rating),2) avg_rating
FROM orders o
JOIN ratings r USING(order_id)
WHERE o.status='Delivered'
GROUP BY duration_band
ORDER BY duration_band;


-- Combined from 12_Supplementary_Analysis.sql
USE smart_delivery_analytics;

-- Supplemental questions close specific gaps in the detailed business-question list.
-- Q51 Payment methods associated with cancellations (association only)
SELECT p.payment_mode,
  COUNT(*) orders_count,
  SUM(o.status='Cancelled') cancelled,
  ROUND(100*SUM(o.status='Cancelled')/COUNT(*),2) cancellation_pct
FROM payments p
JOIN orders o USING(order_id)
GROUP BY p.payment_mode
ORDER BY cancellation_pct DESC;

-- Q52 Delivered item GMV by cuisine
SELECT r.cuisine_type,
  COUNT(*) delivered_orders,
  ROUND(SUM(o.order_amount),2) delivered_item_gmv
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.cuisine_type
ORDER BY delivered_item_gmv DESC;

-- Q53 Average delivered basket value by restaurant operating city
SELECT r.city,
  COUNT(*) delivered_orders,
  ROUND(AVG(o.order_amount),2) avg_delivered_order_value
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.city
ORDER BY avg_delivered_order_value DESC;

-- Q54 Restaurants with the highest average delivered basket values; require 20 completed orders
SELECT r.restaurant_id,
  r.restaurant_name,
  COUNT(*) delivered_orders,
  ROUND(AVG(o.order_amount),2) avg_delivered_order_value
FROM orders o
JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY r.restaurant_id,
  r.restaurant_name
HAVING COUNT(*)>=20
ORDER BY avg_delivered_order_value DESC
LIMIT 15;

-- Q55 Top ten restaurant contribution to delivered item GMV
WITH restaurant_gmv AS (
  SELECT restaurant_id,SUM(order_amount) gmv
  FROM orders
  WHERE status='Delivered'
  GROUP BY restaurant_id),
  ranked AS (
  SELECT *,ROW_NUMBER() OVER(
    ORDER BY gmv DESC) rn
  FROM restaurant_gmv)
SELECT ROUND(SUM(CASE WHEN rn<=10 THEN gmv ELSE 0 END),2) top10_gmv,
  ROUND(SUM(gmv),2) all_restaurants_gmv,
  ROUND(100*SUM(CASE WHEN rn<=10 THEN gmv ELSE 0 END)/SUM(gmv),2) top10_share_pct
FROM ranked;

-- Q56 Inactive customer detail, using the January 2025 snapshot cutoff
SELECT c.customer_id,
  c.customer_name,
  c.city,
  b.last_order_days,
  b.total_orders,
  b.total_spending,
  b.churn_flag
FROM customers c
JOIN customer_behavior b USING(customer_id)
WHERE b.last_order_days>90
ORDER BY b.last_order_days DESC,
  b.total_spending DESC
LIMIT 50;

-- Q57 Delivery partner volume, success share, cancellations and rating
SELECT d.partner_id,
  d.partner_name,
  d.vehicle_type,
  COUNT(o.order_id) assigned_orders,
  SUM(o.status='Delivered') successful_deliveries,
  ROUND(100*SUM(o.status='Delivered')/COUNT(o.order_id),2) successful_delivery_pct,
  SUM(o.status='Cancelled') cancellations,
  ROUND(AVG(rt.customer_rating),2) avg_rating
FROM delivery_partners d
JOIN orders o USING(partner_id)
LEFT JOIN ratings rt USING(order_id)
GROUP BY d.partner_id,
  d.partner_name,
  d.vehicle_type
ORDER BY successful_deliveries DESC;

-- Q58 Fastest delivery partners overall, minimum 20 deliveries
SELECT d.partner_id,
  d.partner_name,
  COUNT(*) delivered_orders,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60,2) avg_minutes
FROM orders o
JOIN delivery_partners d USING(partner_id)
WHERE o.status='Delivered'
GROUP BY d.partner_id,
  d.partner_name
HAVING COUNT(*)>=20
ORDER BY avg_minutes,
  delivered_orders DESC
LIMIT 15;

-- Q59 Delivery speed by vehicle type
SELECT d.vehicle_type,
  COUNT(*) delivered_orders,
  ROUND(AVG(TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time))/60,2) avg_minutes
FROM orders o
JOIN delivery_partners d USING(partner_id)
WHERE o.status='Delivered'
GROUP BY d.vehicle_type
ORDER BY avg_minutes;

