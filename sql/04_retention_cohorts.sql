-- Деление пользователей на когорты по дате первого заказа. 
SELECT 
	DATE(first_time_order_ts) AS first_time_order,
	user_id,
	COUNT(user_id) OVER(PARTITION BY DATE(first_time_order_ts)) AS cohort_size
FROM
	(SELECT user_id, MIN(created_ts) AS first_time_order_ts
	FROM orders
	GROUP BY user_id)
ORDER BY first_time_order, user_id
LIMIT 100

-- Определение доли пользователей в каждой когорте, которые сделали заказ на следующий день после своего первого заказа, через неделю после своего первого заказа. 
WITH cohorts AS(SELECT user_id, DATE(MIN(created_ts)) AS first_time_order
	FROM orders
	GROUP BY user_id),
	activity AS(SELECT DISTINCT user_id, DATE(created_ts) AS order_date FROM orders)
	
SELECT
	c.first_time_order,
	COUNT(DISTINCT c.user_id) AS cohort_size,
	ROUND(CAST(COUNT(DISTINCT c.user_id) FILTER(WHERE a.order_date - c.first_time_order = 1) AS REAL) / COUNT(DISTINCT c.user_id), 3) AS D1_retention,
	ROUND(CAST(COUNT(DISTINCT c.user_id) FILTER(WHERE a.order_date - c.first_time_order = 7) AS REAL) / COUNT(DISTINCT c.user_id), 3) AS D7_retention
FROM cohorts AS c
LEFT JOIN activity AS a
ON c.user_id = a.user_id
GROUP BY first_time_order
ORDER BY first_time_order

-- Для каждой когорты пользователей (когорта определяется по неделе первого заказа)
-- считаем в динамике количество пользователей по неделям и retention для каждой когорты по неделям.
WITH cohorts AS (SELECT user_id, date(MIN(created_ts), 'weekday 1', '-7 days') AS first_week_order
				FROM orders
				GROUP BY user_id),
	week_activity AS (SELECT DISTINCT user_id, date(created_ts, 'weekday 1', '-7 days') AS order_week
				FROM orders),
	for_retention AS (SELECT c.user_id, c.first_week_order, a.order_week, 
				CAST((julianday(a.order_week) - julianday(c.first_week_order)) / 7 AS INTEGER) AS week_number
				FROM cohorts AS c
				JOIN week_activity AS a
				ON c.user_id = a.user_id),
	size AS (SELECT first_week_order, COUNT(DISTINCT user_id) AS cohort_size
				FROM
					(SELECT DISTINCT first_week_order, user_id
					FROM cohorts) t
				GROUP BY first_week_order),
	retention AS (SELECT r.user_id, r.first_week_order, r.order_week, r.week_number, s.cohort_size
				FROM for_retention AS r
				JOIN size AS s
				ON r.first_week_order = s.first_week_order)

SELECT 
	first_week_order, 
	week_number, 
	COUNT(DISTINCT user_id) AS active_users,
	ROUND(CAST(COUNT(DISTINCT user_id) AS REAL) / MAX(cohort_size), 3) AS retention_by_weeks
FROM retention
GROUP BY first_week_order, week_number
ORDER BY first_week_order, week_number
LIMIT 1000