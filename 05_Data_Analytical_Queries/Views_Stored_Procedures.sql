-- Combined from 10_Views_Procedures.sql
USE smart_delivery_analytics;

CREATE OR REPLACE VIEW vw_order_details AS
SELECT o.order_id,o.customer_id,c.customer_name,o.restaurant_id,r.restaurant_name,r.city restaurant_city,
       o.partner_id,d.partner_name,d.vehicle_type,o.order_time,o.delivered_time,o.status,
       o.order_amount,o.delivery_fee,p.payment_mode,p.amount payment_amount,rt.customer_rating
FROM orders o JOIN customers c USING(customer_id) JOIN restaurants r USING(restaurant_id)
LEFT JOIN delivery_partners d USING(partner_id)
LEFT JOIN payments p USING(order_id) LEFT JOIN ratings rt USING(order_id);

CREATE OR REPLACE VIEW vw_restaurant_performance AS
SELECT r.restaurant_id,r.restaurant_name,r.city,r.cuisine_type,
       COUNT(o.order_id) order_count,SUM(o.status='Delivered') delivered_count,
       SUM(o.status='Cancelled') cancelled_count,
       ROUND(100*SUM(o.status='Cancelled')/NULLIF(COUNT(o.order_id),0),2) cancellation_pct,
       ROUND(SUM(CASE WHEN o.status='Delivered' THEN o.order_amount ELSE 0 END),2) delivered_item_gmv,
       ROUND(AVG(CASE WHEN o.status='Delivered' THEN TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time)/60 END),2) avg_delivery_minutes
FROM restaurants r LEFT JOIN orders o USING(restaurant_id)
GROUP BY r.restaurant_id,r.restaurant_name,r.city,r.cuisine_type;

CREATE OR REPLACE VIEW vw_partner_performance AS
SELECT d.partner_id,d.partner_name,d.vehicle_type,
       COUNT(o.order_id) assigned_orders,SUM(o.status='Delivered') delivered_orders,
       SUM(o.status='Cancelled') cancelled_orders,
       ROUND(100*SUM(o.status='Cancelled')/NULLIF(COUNT(o.order_id),0),2) cancellation_pct,
       ROUND(AVG(CASE WHEN o.status='Delivered' THEN TIMESTAMPDIFF(SECOND,o.order_time,o.delivered_time)/60 END),2) avg_delivery_minutes,
       ROUND(AVG(rt.customer_rating),2) avg_customer_rating
FROM delivery_partners d LEFT JOIN orders o USING(partner_id)
LEFT JOIN ratings rt USING(order_id)
GROUP BY d.partner_id,d.partner_name,d.vehicle_type;

CREATE OR REPLACE VIEW vw_customer_behavior_snapshot AS
SELECT c.customer_id,c.customer_name,c.city,c.signup_date,b.total_orders reported_total_orders,
       b.total_spending reported_total_spending,b.avg_order_value reported_avg_order_value,
       b.last_order_days,b.churn_flag,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id=c.customer_id) observed_order_rows
FROM customers c JOIN customer_behavior b USING(customer_id);

CREATE OR REPLACE VIEW vw_monthly_city_delivered_gmv AS
SELECT DATE_FORMAT(o.order_time,'%Y-%m') order_month,r.city,
       COUNT(*) delivered_orders,ROUND(SUM(o.order_amount),2) delivered_item_gmv
FROM orders o JOIN restaurants r USING(restaurant_id)
WHERE o.status='Delivered'
GROUP BY DATE_FORMAT(o.order_time,'%Y-%m'),r.city;

DELIMITER $$
CREATE PROCEDURE sp_monthly_operations_summary(IN p_year INT, IN p_month INT)
BEGIN
  SELECT COUNT(*) total_orders,
         SUM(status='Delivered') delivered_orders,
         SUM(status='Cancelled') cancelled_orders,
         SUM(status='Pending') pending_orders,
         ROUND(100*SUM(status='Cancelled')/NULLIF(COUNT(*),0),2) cancellation_pct,
         ROUND(SUM(CASE WHEN status='Delivered' THEN order_amount ELSE 0 END),2) delivered_item_gmv,
         ROUND(AVG(CASE WHEN status='Delivered' THEN TIMESTAMPDIFF(SECOND,order_time,delivered_time)/60 END),2) avg_delivery_minutes
  FROM orders
  WHERE YEAR(order_time)=p_year AND MONTH(order_time)=p_month;
END$$
DELIMITER ;

-- Example execution for validation:
-- CALL sp_monthly_operations_summary(2024,10);
