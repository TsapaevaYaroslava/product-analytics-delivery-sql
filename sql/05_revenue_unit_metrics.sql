-- Подсчет общего объема продаж через платформу по неделям (GMV) с учетом промо-скидок.
-- Подсчет среднего чека (AOV) за неделю.
-- GMV считается за вычетом скидок, чтобы посмотреть на реальный денежный поток, проходящий через платформу. 
SELECT 
	order_week, 
	week_orders,
	week_revenue - week_discount AS net_week_GMV,
	ROUND(CAST(week_revenue - week_discount AS REAL) / week_orders, 2) AS week_AOV
FROM
	(SELECT 
		order_week, 
		SUM(total_amount) AS week_revenue, 
		SUM(promo_discount) AS week_discount,
		COUNT(order_id) AS week_orders
	FROM
		(SELECT DATE(created_ts, 'weekday 1', '-7 days') AS order_week, total_amount, order_id, promo_discount
		FROM orders
		WHERE delivered_ts IS NOT NULL) t
	GROUP BY order_week) t1
ORDER BY order_week
LIMIT 100;

-- Сравнение двух групп людей: которые получили промо-скидку и не получили. 
-- Сравнение количества заказов в обеих группах, выручки, среднего размера скидки и среднего размера чека.
SELECT 
	promo_orders, 
	SUM(net_amount) AS revenue, 
	COUNT(order_id) AS total_orders,
	ROUND(CAST(COUNT(order_id) AS REAL) / (SELECT COUNT(order_id) FROM orders WHERE delivered_ts IS NOT NULL), 3) AS orders_share,
	CASE 
		WHEN promo_orders = 'промо-заказ' THEN (SELECT ROUND(AVG(promo_discount), 2) FROM orders WHERE promo_discount > 0 AND delivered_ts IS NOT NULL)
		ELSE 0 END AS avg_promo_discount,
	ROUND(CAST(SUM(net_amount) AS REAL) / COUNT(order_id), 2) AS AOV
FROM
	(SELECT 
		order_id,
		total_amount,
		promo_discount,
		total_amount - promo_discount AS net_amount,
		CASE WHEN promo_discount > 0 THEN 'промо-заказ' ELSE 'обычный заказ' END AS promo_orders
	FROM orders
	WHERE delivered_ts IS NOT NULL)
GROUP BY promo_orders;
-- Примерно 75% пользователей делали заказ без скидки. Средний чек: 1300,96 рублей. 
-- 25% пользователей сделали заказ со скидкой. Средний размер скидки составил 195,22 рубля, а средний чек 1101,05 рублей. 

-- Расчет средней выручки с одного активного пользователя по месяцам (ARPU).
SELECT
	ROUND(CAST(month_net_GMV AS REAL) / MAU, 3) AS month_ARPU,
	month,
	year
FROM
	(SELECT 
		COUNT(DISTINCT user_id) AS MAU, 
		SUM(total_amount) - SUM(promo_discount) AS month_net_GMV, 
		month, 
		year
	FROM
		(SELECT user_id, total_amount, promo_discount, STRFTIME('%m', created_ts) AS month, STRFTIME('%Y', created_ts) AS year
		FROM orders
		WHERE delivered_ts IS NOT NULL)
	GROUP BY month, year)
ORDER BY year, month