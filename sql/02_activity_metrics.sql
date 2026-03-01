-- Определение активности пользователей по дням, неделям, месяцам (DAU|WAU|MAU)
-- DAU:
SELECT DATE(created_ts) AS date, COUNT(user_id) AS DAU
FROM orders
GROUP BY DATE(created_ts)
ORDER BY date
LIMIT 1000

-- WAU:
SELECT COUNT(user_id) AS WAU, week, year
FROM
	(SELECT user_id, STRFTIME('%W', created_ts) AS week, STRFTIME('%Y', created_ts) AS year
	FROM orders)
GROUP BY week, year
ORDER BY week, year

-- MAU:
SELECT COUNT(user_id) AS MAU, month, year
FROM
	(SELECT user_id, STRFTIME('%m', created_ts) AS month, STRFTIME('%Y', created_ts) AS year
	FROM orders)
GROUP BY month, year
ORDER BY month, year;

-- Динамика количества заказов на одного пользователя по дням, по неделям, по месяцам.
-- Количество заказов на одного пользователя в динамике по дням:
SELECT date, ROUND(CAST(daily_orders AS REAL) / daily_users, 3) AS day_order_per_user
FROM
	(SELECT DATE(created_ts) AS date, COUNT(order_id) AS daily_orders, COUNT(DISTINCT user_id) AS daily_users
	FROM orders
	GROUP BY DATE(created_ts))
LIMIT 1000

-- Количество заказов на одного пользователя в динамике по неделям:
SELECT week, year, ROUND(CAST(COUNT(order_id) AS REAL) / COUNT(DISTINCT user_id), 3) AS weekly_order_per_user
FROM
	(SELECT user_id, order_id, STRFTIME('%W', created_ts) AS week, STRFTIME('%Y', created_ts) AS year
	FROM orders)
GROUP BY week, year
ORDER BY week, year

-- Количество заказов на одного пользователя в динамике по месяцам:
SELECT month, year, ROUND(CAST(COUNT(order_id) AS REAL) / COUNT(DISTINCT user_id), 3) AS monthly_order_per_user
FROM
	(SELECT user_id, order_id, STRFTIME('%m', created_ts) AS month, STRFTIME('%Y', created_ts) AS year
	FROM orders)
GROUP BY month, year
ORDER BY month, year;

-- Динамика количества новых и вернувшихся пользователей за каждый день, каждую неделю, каждый месяц.
-- Новые и вернувшиеся пользователи по дням:
WITH first_orders AS (SELECT user_id, MIN(DATE(created_ts)) AS first_time_order
	FROM orders
	GROUP BY user_id),
active_by_date AS (SELECT DISTINCT orders.user_id, DATE(orders.created_ts) AS date, first_orders.first_time_order
    FROM orders
    INNER JOIN first_orders
    ON orders.user_id = first_orders.user_id)
	
SELECT date,
CASE WHEN date = first_time_order THEN 'new' ELSE 'returning' END AS user_type,
COUNT(DISTINCT user_id) AS users_count
FROM active_by_date
GROUP BY date, user_type
ORDER BY date, user_type
LIMIT 1000

-- Новые и вернувшиеся пользователи по неделям:
WITH first_orders AS (SELECT user_id, STRFTIME('%W', MIN(created_ts)) AS first_week, 
	STRFTIME('%Y', MIN(created_ts)) AS first_year
	FROM orders
	GROUP BY user_id),
active_by_week AS (SELECT DISTINCT orders.user_id, STRFTIME('%W', orders.created_ts) AS week, 
	STRFTIME('%Y', orders.created_ts) AS year, 
	first_orders.first_week, first_orders.first_year
	FROM orders
	INNER JOIN first_orders
	ON orders.user_id = first_orders.user_id)
	
SELECT week, year,
CASE WHEN week = first_week AND year = first_year THEN 'new' ELSE 'returning' END AS user_type,
COUNT(DISTINCT user_id) AS users_count
FROM active_by_week
GROUP BY year, week, user_type
ORDER BY year, week, user_type

-- Новые и вернувшиеся пользователи по месяцам:
WITH first_orders AS (SELECT user_id, STRFTIME('%m', MIN(created_ts)) AS first_month, 
	STRFTIME('%Y', MIN(created_ts)) AS first_year
	FROM orders
	GROUP BY user_id),
active_by_month AS (SELECT DISTINCT orders.user_id, STRFTIME('%m', orders.created_ts) AS month, 
	STRFTIME('%Y', orders.created_ts) AS year, 
	first_orders.first_month, first_orders.first_year
	FROM orders
	INNER JOIN first_orders
	ON orders.user_id = first_orders.user_id)
	
SELECT month, year,
CASE WHEN month = first_month AND year = first_year THEN 'new' ELSE 'returning' END AS user_type,
COUNT(DISTINCT user_id) AS users_count
FROM active_by_month
GROUP BY year, month, user_type
ORDER BY year, month, user_type