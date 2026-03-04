-- Подсчет количества строк в каждой таблице.
SELECT COUNT(*) AS orders_cnt FROM orders;
SELECT COUNT(*) AS restaurants_cnt FROM restaurants;
SELECT COUNT(*) AS users_cnt FROM users;
--- orders_cnt = 60000; restaurants_cnt = 120; users_cnt = 12000.

--- Проверка уникальности ключей в таблицах.
SELECT COUNT(user_id) 
FROM users 
GROUP BY user_id 
HAVING(COUNT(user_id) > 1)

SELECT COUNT(restaurant_id) 
FROM restaurants 
GROUP BY restaurant_id 
HAVING(COUNT(restaurant_id) > 1)

SELECT COUNT(order_id) 
FROM orders 
GROUP BY order_id
HAVING(COUNT(order_id) > 1);
--- В таблицах нет дубликатов по id пользователя, заказа и ресторана.

-- Проверка того, что для каждого заказа есть пользователь, который этот заказ сделал. 
-- Проверка того, что для каждого заказа есть информация о ресторане.
SELECT orders.order_id, orders.user_id, users.user_id
FROM orders
LEFT JOIN users
ON orders.user_id = users.user_id
WHERE users.user_id IS NULL

SELECT orders.order_id, orders.restaurant_id, restaurants.restaurant_id
FROM orders
LEFT JOIN restaurants
ON orders.restaurant_id = restaurants.restaurant_id
WHERE restaurants.restaurant_id IS NULL;
-- Данные полные, без поломанных связей.

-- Проверка долей доставленных и отмененных заказов.
SELECT status, ROUND(CAST(order_id_by_status AS REAL) / (SELECT COUNT(order_id) FROM orders) * 100, 2) AS status_ratio
FROM
	(SELECT status, COUNT(order_id) AS order_id_by_status
	FROM orders
	GROUP BY status) t;
-- Доставлено 89,91% заказов, а 10,09% заказов отменено.
