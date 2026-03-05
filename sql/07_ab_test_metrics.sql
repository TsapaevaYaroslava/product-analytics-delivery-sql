-- Подсчет количества пользователей в каждой группе для A/B теста.
SELECT ab_group, ab_users, ROUND(ab_users * 1.0 / SUM(ab_users) OVER(), 2) AS ab_share
FROM
	(SELECT 
		ab_group, 
		COUNT(DISTINCT user_id) AS ab_users
	FROM ab_assignments
	GROUP BY ab_group);

-- Создание рабочей таблицы. Объединение информации о группе пользователя с основными данными из orders. 
-- Подсчет продуктовых метрик для двух групп пользователей: количество доставленных и отмененных заказов,
-- доля доставленных и отмененных заказов, подсчет прибыли, среднего чека, доли пользователей с промо-скидкой,
-- среднее время назначения курьера и среднее время доставки. 
WITH base AS
	(SELECT 
		o.order_id, o.user_id, a.ab_group,
		o.created_ts, ROUND((julianday(o.assigned_ts) - julianday(o.created_ts)) * 1440, 2) AS assign_minutes, 
		o.assigned_ts, 
		CASE 
			WHEN status = 'delivered' THEN ROUND((julianday(o.delivered_ts) - julianday(o.created_ts)) * 1440, 2)
			ELSE NULL 
		END AS delivery_minutes,
		o.delivered_ts, o.canceled_ts,
		o.total_amount, o.delivery_fee, o.promo_discount,
		CASE
			WHEN o.promo_discount > 0 THEN 1
			ELSE 0
		END AS is_promo,
		o.total_amount + o.delivery_fee - o.promo_discount AS order_GMV,
		o.status
	FROM orders AS o
	JOIN ab_assignments AS a
	ON o.user_id = a.user_id),

	ab_metrics AS
	(SELECT 
		ab_group,  
		COUNT(DISTINCT user_id) AS users_with_orders,
		COUNT(order_id) AS created_orders,
		COUNT(order_id) FILTER(WHERE status = 'delivered') AS orders_delivered,
		COUNT(order_id) FILTER(WHERE status = 'canceled') AS orders_canceled,
		COUNT(order_id) FILTER(WHERE status = 'delivered') * 1.0 / COUNT(order_id) AS delivered_rate,
		COUNT(order_id) FILTER(WHERE status = 'canceled') * 1.0 / COUNT(order_id) AS cancel_rate,
		SUM(order_GMV) AS total_GMV,
		COUNT(order_id) FILTER (WHERE is_promo = 1) AS orders_with_promo,
		ROUND(COUNT(order_id) FILTER (WHERE is_promo = 1) * 1.0 / COUNT(order_id), 4) AS promo_orders_share,
		ROUND(AVG(order_GMV), 2) AS AOV,
		ROUND(AVG(assign_minutes) FILTER(WHERE assign_minutes IS NOT NULL), 2) AS avg_assign_minutes,
		ROUND(AVG(delivery_minutes) FILTER(WHERE delivery_minutes IS NOT NULL AND status = 'delivered'), 2) AS avg_delivery_minutes
	FROM base
	GROUP BY ab_group)

SELECT 
	delivered_rate, diff_abs_delivered, diff_pct_delivered,
	cancel_rate, diff_abs_cancel, diff_pct_cancel,
	avg_delivery_minutes, diff_abs_delivery_minutes, diff_pct_delivery_minutes
FROM
	(SELECT
	  m.ab_group,
	  ROUND(m.delivered_rate, 4) AS delivered_rate,
	  ROUND((b.delivered_rate - a.delivered_rate), 3) AS diff_abs_delivered,
	  ROUND(((b.delivered_rate - a.delivered_rate) * 1.0 / a.delivered_rate) * 100, 3) AS diff_pct_delivered,
	  ROUND(m.cancel_rate, 4) AS cancel_rate,
	  ROUND((b.cancel_rate - a.cancel_rate), 3) AS diff_abs_cancel,
	  ROUND(((b.cancel_rate - a.cancel_rate) * 1.0 / a.cancel_rate) * 100, 3) AS diff_pct_cancel,
	  ROUND(m.avg_delivery_minutes, 4) AS avg_delivery_minutes,
	  ROUND((b.avg_delivery_minutes - a.avg_delivery_minutes), 3) AS diff_abs_delivery_minutes,
	  ROUND(((b.avg_delivery_minutes - a.avg_delivery_minutes) * 1.0 / a.avg_delivery_minutes) * 100, 3) AS diff_pct_delivery_minutes
	FROM ab_metrics AS m
	CROSS JOIN (SELECT delivered_rate, cancel_rate, avg_delivery_minutes FROM ab_metrics WHERE ab_group = 'A') AS a
	CROSS JOIN (SELECT delivered_rate, cancel_rate, avg_delivery_minutes FROM ab_metrics WHERE ab_group = 'B') AS b
	WHERE m.ab_group IN ('A','B'))
LIMIT 1;
-- Вывод разниц между группами в абсолютном и относительном выражении по основным метрикам.