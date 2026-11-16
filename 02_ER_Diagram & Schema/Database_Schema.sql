-- Smart Delivery Operations Analytics System
-- MySQL 8.0+ schema. This script is non-destructive: it does not drop tables.
-- Apply to an empty smart_delivery_analytics database.

CREATE DATABASE IF NOT EXISTS smart_delivery_analytics
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE smart_delivery_analytics;

CREATE TABLE IF NOT EXISTS customers (
  customer_id INT NOT NULL,
  customer_name VARCHAR(100) NOT NULL,
  age TINYINT UNSIGNED NOT NULL,
  gender VARCHAR(20) NOT NULL,
  city VARCHAR(50) NOT NULL,
  signup_date DATE NOT NULL,
  PRIMARY KEY (customer_id),
  CONSTRAINT chk_customers_age CHECK (age BETWEEN 18 AND 60),
  CONSTRAINT chk_customers_gender CHECK (gender IN ('Male','Female','Other')),
  INDEX idx_customers_city (city)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS restaurants (
  restaurant_id INT NOT NULL,
  restaurant_name VARCHAR(150) NOT NULL,
  cuisine_type VARCHAR(50) NOT NULL,
  city VARCHAR(50) NOT NULL,
  rating DECIMAL(2,1) NOT NULL,
  PRIMARY KEY (restaurant_id),
  CONSTRAINT chk_restaurants_rating CHECK (rating BETWEEN 1.0 AND 5.0),
  INDEX idx_restaurants_city (city),
  INDEX idx_restaurants_cuisine (cuisine_type)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS delivery_partners (
  partner_id INT NOT NULL,
  partner_name VARCHAR(100) NOT NULL,
  vehicle_type VARCHAR(30) NOT NULL,
  joining_date DATE NOT NULL,
  PRIMARY KEY (partner_id),
  CONSTRAINT chk_partners_vehicle CHECK (vehicle_type IN ('Bike','Scooter','Bicycle','Electric Bike'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
  order_id INT NOT NULL,
  customer_id INT NOT NULL,
  restaurant_id INT NOT NULL,
  partner_id INT NULL COMMENT 'Source contains an assignment for every row; NULL allowed for future unassigned orders.',
  order_time DATETIME NOT NULL,
  delivered_time DATETIME NULL COMMENT 'Expected NULL when status is Cancelled or Pending.',
  order_amount DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(8,2) NOT NULL,
  status VARCHAR(20) NOT NULL,
  PRIMARY KEY (order_id),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
  CONSTRAINT fk_orders_partner FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id),
  CONSTRAINT chk_orders_amount CHECK (order_amount >= 0),
  CONSTRAINT chk_orders_fee CHECK (delivery_fee >= 0),
  CONSTRAINT chk_orders_status CHECK (status IN ('Delivered','Cancelled','Pending')),
  CONSTRAINT chk_orders_delivery_time CHECK (delivered_time IS NULL OR delivered_time >= order_time),
  INDEX idx_orders_customer_time (customer_id, order_time),
  INDEX idx_orders_restaurant_time (restaurant_id, order_time),
  INDEX idx_orders_partner_time (partner_id, order_time),
  INDEX idx_orders_status_time (status, order_time)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  payment_id INT NOT NULL,
  order_id INT NOT NULL,
  payment_mode VARCHAR(30) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (payment_id),
  CONSTRAINT uq_payments_order UNIQUE (order_id),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT chk_payments_mode CHECK (payment_mode IN ('UPI','Credit Card','Debit Card','Cash on Delivery','Wallet')),
  CONSTRAINT chk_payments_amount CHECK (amount >= 0),
  INDEX idx_payments_mode (payment_mode)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ratings (
  rating_id INT NOT NULL,
  order_id INT NOT NULL,
  customer_rating DECIMAL(2,1) NOT NULL,
  feedback VARCHAR(255) NULL,
  PRIMARY KEY (rating_id),
  CONSTRAINT uq_ratings_order UNIQUE (order_id),
  CONSTRAINT fk_ratings_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT chk_ratings_score CHECK (customer_rating BETWEEN 1.0 AND 5.0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customer_behavior (
  customer_id INT NOT NULL,
  total_orders INT NOT NULL,
  total_spending DECIMAL(12,2) NOT NULL,
  avg_order_value DECIMAL(10,2) NOT NULL,
  last_order_days SMALLINT UNSIGNED NOT NULL,
  churn_flag TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (customer_id),
  CONSTRAINT fk_behavior_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT chk_behavior_orders CHECK (total_orders >= 0),
  CONSTRAINT chk_behavior_spending CHECK (total_spending >= 0),
  CONSTRAINT chk_behavior_aov CHECK (avg_order_value >= 0),
  CONSTRAINT chk_behavior_churn CHECK (churn_flag IN (0,1))
) ENGINE=InnoDB;
