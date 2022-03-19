SELECT * FROM runners;
SELECT * FROM customer_orders;
SELECT * FROM runner_orders;
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;

-- Clean Data

-- Clean customer_orders table
-- Copying table to new table
DROP TABLE IF EXISTS customer_orders1;
CREATE TABLE customer_orders1 AS
(SELECT order_id, customer_id, pizza_id, exclusions, extras, order_time 
FROM customer_orders);
-- Cleaning data
UPDATE customer_orders1
SET 
exclusions = CASE exclusions WHEN 'null' THEN NULL ELSE exclusions END,
extras = CASE extras WHEN 'null' THEN NULL ELSE extras END;

SELECT * FROM customer_orders1;

-- Clean runner_orders table
-- Copying table to new table and cleaning data
DROP TABLE IF EXISTS runner_orders1;
CREATE TABLE runner_orders1 AS
(SELECT order_id, runner_id, pickup_time,
CASE
WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
 ELSE distance 
END AS distance,
CASE
 WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
 WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
 WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
 ELSE duration
END AS duration, cancellation 
FROM runner_orders);
-- Cleaning data
UPDATE runner_orders1
SET 
pickup_time = CASE pickup_time WHEN 'null' THEN NULL ELSE pickup_time END,
distance = CASE distance WHEN 'null' THEN NULL ELSE distance END,
duration = CASE duration WHEN 'null' THEN NULL ELSE duration END,
cancellation = CASE cancellation WHEN 'null' THEN NULL ELSE cancellation END;

SELECT * FROM runner_orders1;
-- Covert Datatypes

-- The datatypes for distance and duration column is VARCHAR but they are numbers
-- Convert into DECIMAL and INT data type respectively
-- The cancellation column is VARCHAR but it is a timestamp
-- Convert the datatype to DATETIME
-- Updating datatypes for runner_orders1 table
ALTER TABLE runner_orders1
MODIFY COLUMN pickup_time DATETIME NULL,
MODIFY COLUMN distance DECIMAL(5,1) NULL,
MODIFY COLUMN duration INT NULL;
SELECT * FROM runner_orders1;


-- PIZZA METRICS ANALYSIS

-- 1. How many pizzas were ordered?
SELECT COUNT(pizza_id) AS TotalPizzaOrdered
FROM customer_orders1;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) AS TotalUniqueCustomerOrders
FROM customer_orders1;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(runner_id) AS SuccessfulOrders
FROM runner_orders1
WHERE distance IS NOT NULL
GROUP BY runner_id; 

-- 4. How many of each type of pizza was delivered?
SELECT pizza_names.pizza_name, COUNT(customer_orders1.pizza_id) AS TotalDelivered
FROM customer_orders1
INNER JOIN runner_orders1
ON runner_orders1.order_id = customer_orders1.order_id
INNER JOIN pizza_names
ON pizza_names.pizza_id = customer_orders1.pizza_id
WHERE runner_orders1.distance IS NOT NULL
GROUP BY pizza_names.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_orders1.customer_id, pizza_names.pizza_name, COUNT(customer_orders1.pizza_id) AS TotalPizzaOrdered
FROM customer_orders1
INNER JOIN pizza_names
ON pizza_names.pizza_id = customer_orders1.pizza_id
GROUP BY customer_orders1.customer_id, pizza_names.pizza_name
ORDER BY customer_orders1.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT customer_orders1.order_id, COUNT(customer_orders1.pizza_id) AS TotalPizzaDelivered
FROM customer_orders1
INNER JOIN runner_orders1
ON runner_orders1.order_id = customer_orders1.order_id
GROUP BY runner_orders1.order_id
ORDER BY TotalPizzaDelivered DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_orders1.customer_id, 
SUM(CASE
WHEN (exclusions IS NOT NULL AND exclusions != 0) OR (extras IS NOT NULL AND extras != 0) THEN 1
ELSE 0 END) AS AtleastOneChange,
SUM(CASE 
WHEN (exclusions IS NOT NULL OR exclusions = 0) AND (extras IS NOT NULL OR extras = 0) THEN 1
ELSE 0 END) AS NoChange
FROM customer_orders1
INNER JOIN runner_orders1
ON runner_orders1.order_id = customer_orders1.order_id
WHERE runner_orders1.distance != 0
GROUP BY customer_orders1.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT customer_orders1.customer_id, 
SUM(CASE
WHEN (exclusions IS NOT NULL AND exclusions != 0) AND (extras IS NOT NULL AND extras != 0) THEN 1
ELSE 0
END) AS BothExclusionsExtras
FROM customer_orders1
INNER JOIN runner_orders1
ON runner_orders1.order_id = customer_orders1.order_id
WHERE runner_orders1.distance != 0
GROUP BY customer_orders1.customer_id
ORDER BY BothExclusionsExtras DESC;
-- to also know the pizza name
SELECT customer_orders1.customer_id, pizza_names.pizza_name, 
SUM(CASE
WHEN (exclusions IS NOT NULL AND exclusions != 0) AND (extras IS NOT NULL AND extras != 0) THEN 1
ELSE 0
END) AS BothExclusionsExtras
FROM customer_orders1
INNER JOIN pizza_names
ON pizza_names.pizza_id = customer_orders1.pizza_id
INNER JOIN runner_orders1
ON runner_orders1.order_id = customer_orders1.order_id
WHERE runner_orders1.distance != 0
GROUP BY customer_orders1.customer_id, pizza_names.pizza_name
ORDER BY BothExclusionsExtras DESC;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS HourlyData, COUNT(order_id) AS TotalPizzaOrdered
FROM customer_orders1
GROUP BY HourlyData
ORDER BY HourlyData;

-- 10. What was the volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS DailyData, COUNT(order_id) as TotalPizzaOrdered
FROM customer_orders1
GROUP BY DailyData
ORDER BY TotalPizzaOrdered DESC;