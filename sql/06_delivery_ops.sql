-- Расчет среднего и медианного времени доставки заказов. 
-- Расчет доли заказов, которые были доставлены менее чем за 45 минут. 
WITH avg_time AS(SELECT 
					order_id, 
					ROUND((julianday(delivered_ts) - julianday(created_ts)) * 1440, 2) AS delivery_time
				FROM orders
				WHERE delivered_ts IS NOT NULL),
	median_time AS (SELECT
					delivery_time,
					ROW_NUMBER() OVER(ORDER BY delivery_time) AS rn,
					COUNT(*) OVER() AS total
				  FROM avg_time)

SELECT
	ROUND(CAST(COUNT(order_id) FILTER(WHERE delivery_time < 45) AS REAL) / COUNT(order_id), 2) AS share_orders_less_45_minutes,
	avg_delivery_time,
	median_delivery_time
FROM
	(SELECT
		order_id, 
		delivery_time,
		ROUND(AVG(delivery_time) OVER(), 2) AS avg_delivery_time,
		(SELECT AVG(delivery_time)
		FROM median_time
		WHERE rn IN ((total + 1)/2, (total + 2)/2)) AS median_delivery_time
	FROM avg_time)
LIMIT 1;
-- Среднее время доставки составляет 46,93 минуты, а медианное - 47 минут. 
-- Около 45% заказов были доставлены менее чем за 45 минут.

-- Расчет среднего времени от момента создания заказа до назначения курьера в разрезе городов.
SELECT
	city, 
	ROUND(AVG(at - ct), 2) AS assignment_time_minutes
FROM
	(SELECT julianday(o.created_ts) * 1440 AS ct, julianday(o.assigned_ts) * 1440 AS at, r.city
	FROM orders AS o
	JOIN restaurants AS r
	ON o.restaurant_id = r.restaurant_id
	WHERE delivered_ts IS NOT NULL AND assigned_ts IS NOT NULL)
GROUP BY city
ORDER BY assignment_time_minutes, city;
-- В Москве и Санкт-Петербурге среднее время назначения курьера равно 6,97 минут, а в Казани - 7,02.

-- Подсчет различных метрик в разрезе городов и типов ресторанов. 
-- Считается количество отмен в ресторане каждой категории по городам. А также доля отмен в общих отменах в этом городе. 
-- Подсчет количества активных пользователей в ресторане каждой категории по городам и подсчет ARPU. 
WITH base AS (SELECT 
				r.restaurant_id, r.city, r.category, 
				o.order_id, o.user_id, o.total_amount, o.promo_discount, o.status
			FROM restaurants AS r
			JOIN orders AS o
			ON r.restaurant_id = o.restaurant_id),
	cancellation AS (SELECT 
						city, 
						category, 
						canceled_orders, 
						ROUND(CAST(canceled_orders AS REAL) / SUM(canceled_orders) OVER(PARTITION BY city), 2) AS cancellation_share_by_category
					FROM 
						(SELECT 
							city, 
							category, 
							COUNT(order_id) AS canceled_orders
						FROM BASE
						WHERE status = 'canceled'
						GROUP BY city, category)),
	profit AS (SELECT
					city,
					category,
					active_users,
					ROUND(net_GMV / active_users, 2) AS ARPU
				FROM
				(SELECT 
					city, 
					category, 
					COUNT(DISTINCT user_id) AS active_users, 
					SUM(total_amount) - SUM(promo_discount) AS net_GMV
				FROM base
				WHERE status = 'delivered'
				GROUP BY city, category))

SELECT
	c.city, c.category, c.canceled_orders, c.cancellation_share_by_category,
	p.active_users, p.ARPU
FROM cancellation AS c
JOIN profit AS p
ON c.city = p.city AND c.category = p.category
ORDER BY c.city, c.category