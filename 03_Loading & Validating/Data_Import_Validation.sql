-- Combined from 03_Data_Import.sql
-- MySQL 8.0+; execute with mysql --local-infile=1.
-- Source paths use the project workspace. Update the directory if relocated.
SET GLOBAL local_infile = 1;

USE smart_delivery_analytics;

SET FOREIGN_KEY_CHECKS=1;


LOAD DATA LOCAL INFILE '/Users/vakkantivishnu/Downloads/SQL_MAIN_PROJECT/01_Data/customers.csv'
INTO TABLE customers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(customer_id,customer_name,age,gender,city,signup_date);


LOAD DATA LOCAL INFILE '/Users/vakkantivishnu/Downloads/SQL_MAIN_PROJECT/01_Data/restaurants.csv'
INTO TABLE restaurants CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(restaurant_id,restaurant_name,cuisine_type,city,rating);


LOAD DATA LOCAL INFILE '/Users/vakkantivishnu/Downloads/SQL_MAIN_PROJECT/01_Data/delivery_partners.csv'
INTO TABLE delivery_partners CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(partner_id,partner_name,vehicle_type,joining_date);


LOAD DATA LOCAL INFILE '/Users/vakkantivishnu/Downloads/SQL_MAIN_PROJECT/01_Data/orders.csv'
INTO TABLE orders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(order_id,customer_id,restaurant_id,partner_id,order_time,@delivered_time,order_amount,delivery_fee,status)
SET delivered_time=NULLIF(@delivered_time,'');


LOAD DATA LOCAL INFILE '/Users/vakkantivishnu/Downloads/SQL_MAIN_PROJECT/01_Data/payments.csv'
INTO TABLE payments CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(payment_id,order_id,payment_mode,amount);


LOAD DATA LOCAL INFILE '/Users/vakkantivishnu/Downloads/SQL_MAIN_PROJECT/01_Data/ratings.csv'
INTO TABLE ratings CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(rating_id,order_id,customer_rating,feedback);


LOAD DATA LOCAL INFILE '/Users/vakkantivishnu/Downloads/SQL_MAIN_PROJECT/01_Data/customer_behavior.csv'
INTO TABLE customer_behavior CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(customer_id,total_orders,total_spending,avg_order_value,last_order_days,churn_flag);


-- SOURCE 04_SQL_Scripts/04_Data_Validation.sql;

-- Combined from 04_Data_Validation.sql
USE smart_delivery_analytics;
SELECT 'customers' table_name,
  COUNT(*) actual_rows,
  1000 expected_rows
FROM customers
UNION ALL
SELECT 'restaurants',
  COUNT(*),
  100
FROM restaurants
UNION ALL
SELECT 'delivery_partners',
  COUNT(*),
  200
FROM delivery_partners
UNION ALL
SELECT 'orders',
  COUNT(*),
  10000
FROM orders
UNION ALL
SELECT 'payments',
  COUNT(*),
  10000
FROM payments
UNION ALL
SELECT 'ratings',
  COUNT(*),
  7000
FROM ratings
UNION ALL
SELECT 'customer_behavior',
  COUNT(*),
  1000
FROM customer_behavior;
SELECT 'orphan_orders_customer' check_name,
  COUNT(*) violations
FROM orders o
LEFT JOIN customers c USING(customer_id)
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'orphan_orders_restaurant',
  COUNT(*)
FROM orders o
LEFT JOIN restaurants r USING(restaurant_id)
WHERE r.restaurant_id IS NULL
UNION ALL
SELECT 'orphan_orders_partner',
  COUNT(*)
FROM orders o
LEFT JOIN delivery_partners p USING(partner_id)
WHERE o.partner_id IS NOT NULL
  AND p.partner_id IS NULL
UNION ALL
SELECT 'orphan_payments_order',
  COUNT(*)
FROM payments p
LEFT JOIN orders o USING(order_id)
WHERE o.order_id IS NULL
UNION ALL
SELECT 'orphan_ratings_order',
  COUNT(*)
FROM ratings r
LEFT JOIN orders o USING(order_id)
WHERE o.order_id IS NULL
UNION ALL
SELECT 'orphan_behavior_customer',
  COUNT(*)
FROM customer_behavior b
LEFT JOIN customers c USING(customer_id)
WHERE c.customer_id IS NULL;
SELECT status,
  COUNT(*) orders_count,
  SUM(delivered_time IS NULL) missing_delivered_time
FROM orders
GROUP BY status
ORDER BY status;
SELECT COUNT(*) payment_amount_mismatches
FROM payments p
JOIN orders o USING(order_id)
WHERE p.amount <> o.order_amount+o.delivery_fee;
SELECT COUNT(*) invalid_rating_rows
FROM ratings
WHERE customer_rating NOT BETWEEN 1
  AND 5;
SELECT COUNT(*) timestamp_sequence_violations
FROM orders
WHERE delivered_time IS NOT NULL
  AND delivered_time<order_time;

