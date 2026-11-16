-- Combined from 05_Data_Cleaning.sql
-- Preserve the imported raw tables. Audit first; standardization below is idempotent.
USE smart_delivery_analytics;
SELECT 'customer_text_whitespace' issue,
  COUNT(*) rows_affected
FROM customers
WHERE customer_name<>TRIM(customer_name)
  OR city<>TRIM(city)
UNION ALL
SELECT 'restaurant_text_whitespace',
  COUNT(*)
FROM restaurants
WHERE restaurant_name<>TRIM(restaurant_name)
  OR cuisine_type<>TRIM(cuisine_type)
  OR city<>TRIM(city)
UNION ALL
SELECT 'partner_text_whitespace',
  COUNT(*)
FROM delivery_partners
WHERE partner_name<>TRIM(partner_name)
  OR vehicle_type<>TRIM(vehicle_type)
UNION ALL
SELECT 'payment_mode_whitespace',
  COUNT(*)
FROM payments
WHERE payment_mode<>TRIM(payment_mode);


START TRANSACTION;
UPDATE customers
SET customer_name=TRIM(customer_name),
  city=TRIM(city)
WHERE customer_name<>TRIM(customer_name)
  OR city<>TRIM(city);

UPDATE restaurants SET restaurant_name=TRIM(restaurant_name),cuisine_type=TRIM(cuisine_type),city=TRIM(city)
 WHERE restaurant_name<>TRIM(restaurant_name) OR cuisine_type<>TRIM(cuisine_type) OR city<>TRIM(city);

UPDATE delivery_partners SET partner_name=TRIM(partner_name),vehicle_type=TRIM(vehicle_type)
 WHERE partner_name<>TRIM(partner_name) OR vehicle_type<>TRIM(vehicle_type);
UPDATE payments
SET payment_mode=TRIM(payment_mode)
WHERE payment_mode<>TRIM(payment_mode);

COMMIT;


-- Expected from audited source: zero rows changed. Do not fill valid NULL delivery timestamps.

-- Combined from 06_EDA.sql
USE smart_delivery_analytics;
SELECT status,
  COUNT(*) order_count,
  ROUND(100*COUNT(*)/(
    SELECT COUNT(*)
    FROM orders),2) pct
FROM orders
GROUP BY status
ORDER BY order_count DESC;
SELECT city,
  COUNT(*) customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;
SELECT city,
  COUNT(*) restaurant_count
FROM restaurants
GROUP BY city
ORDER BY restaurant_count DESC;
SELECT cuisine_type,
  COUNT(*) restaurant_count,
  ROUND(AVG(rating),2) avg_restaurant_rating
FROM restaurants
GROUP BY cuisine_type
ORDER BY restaurant_count DESC;
SELECT ROUND(SUM(order_amount),2) order_value_total,
  ROUND(AVG(order_amount),2) avg_order_value,
  ROUND(AVG(delivery_fee),2) avg_delivery_fee
FROM orders;
SELECT status,
  COUNT(*) orders_count,
  ROUND(AVG(TIMESTAMPDIFF(MINUTE,order_time,delivered_time)),2) avg_delivery_minutes
FROM orders
GROUP BY status;
SELECT ROUND(AVG(customer_rating),2) avg_customer_rating,
  MIN(customer_rating) min_rating,
  MAX(customer_rating) max_rating
FROM ratings;
SELECT vehicle_type,
  COUNT(*) partners
FROM delivery_partners
GROUP BY vehicle_type
ORDER BY partners DESC;

