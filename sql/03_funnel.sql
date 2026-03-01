-- Подсчет количества заказов, которые были созданы, назначены курьерам, получены курьерами и доставлены заказчику.
-- Расчет конверсии между каждой парой шагов.
SELECT 
	created_orders, 
	ROUND(CAST(assigned_orders AS REAL) / created_orders, 3) AS funnel_assigned_created, 
	assigned_orders, 
	ROUND(CAST(picked_up_orders AS REAL) / assigned_orders, 3) AS funnel_picked_up_assigned,
	picked_up_orders, 
	ROUND(CAST(delivered_orders AS REAL) / picked_up_orders, 3) AS funnel_delivered_picked_up,
	delivered_orders
FROM
	(SELECT 
		COUNT(order_id) FILTER(WHERE created_ts IS NOT NULL) AS created_orders,
		COUNT(order_id) FILTER(WHERE assigned_ts IS NOT NULL) AS assigned_orders,
		COUNT(order_id) FILTER(WHERE picked_up_ts IS NOT NULL) AS picked_up_orders,
		COUNT(order_id) FILTER(WHERE delivered_ts IS NOT NULL) AS delivered_orders
	FROM orders);

-- Расчет доли отмененных заказов в общем количестве заказов. 
-- Расчет доли отмененных заказов до назначения курьера и после назначения курьера.
SELECT 
	ROUND(CAST(total_canceled AS REAL) / total_orders, 3) AS total_canceled_ratio,
	ROUND(CAST(canceled_before_assigned AS REAL) / total_orders, 3) AS canceled_before_assigned_ratio,
	ROUND(CAST(canceled_after_assigned AS REAL) / total_orders, 3) AS canceled_after_assigned_ratio
FROM
	(SELECT 
	COUNT(order_id) FILTER(WHERE canceled_ts IS NOT NULL AND assigned_ts IS NULL) AS canceled_before_assigned,
	COUNT(order_id) FILTER(WHERE canceled_ts IS NOT NULL AND assigned_ts IS NOT NULL) AS canceled_after_assigned,
	COUNT(order_id) FILTER(WHERE canceled_ts IS NOT NULL) AS total_canceled,
	COUNT(order_id) AS total_orders
	FROM orders);
-- Было отменено 10,1% заказов. Все заказы были отменены после того, как был назначен курьер.

-- Подсчет количества отмененных заказов по различным причинам.
SELECT 
	cancel_reason, 
	canceled_orders_by_reason, 
	ROUND(CAST(canceled_orders_by_reason AS REAL) / total_canceled, 3) AS canceled_ratio
FROM
	(SELECT cancel_reason, COUNT(order_id) AS canceled_orders_by_reason, SUM(COUNT(order_id)) OVER() AS total_canceled
	FROM orders
	WHERE status = 'canceled'
	GROUP BY cancel_reason
	ORDER BY canceled_orders_by_reason DESC)
-- Заказы примерно в равной степени отменяются из-за курьеров, клиентов и ресторанов.
-- Доля отмененных заказов из-за курьера - 0,344; из-за клиента - 0,333; из-за ресторана - 0,324.