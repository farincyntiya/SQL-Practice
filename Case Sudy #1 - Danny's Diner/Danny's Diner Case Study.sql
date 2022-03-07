SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

-- Combine Tables
CREATE VIEW combined_sales AS
(SELECT s.customer_id, order_date, mm.join_date, s.product_id, product_name, price,
CASE WHEN join_date <= order_date THEN 'member' else 'non member' END stat
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members mm
ON s.customer_id = mm.customer_id);
-- See Combined Tables
SELECT * FROM combined_sales;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS "total amount spent"
FROM combined_sales
GROUP BY customer_id
ORDER BY SUM(price) DESC;

-- 2. How many days have each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) AS "visited restaurant (days)"
FROM combined_sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM combined_sales
WHERE order_date = (
SELECT MIN(order_date)
FROM combined_sales);

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(*) AS "times purchased"
FROM combined_sales
GROUP BY product_name
ORDER BY COUNT(*) DESC;
-- the most purchased item on the menu is ramen
SELECT customer_id, product_name, COUNT(*) AS "times purchased"
FROM combined_sales
WHERE product_name = "ramen"
GROUP BY customer_id;

-- 5. Which item was the most popular for each customer?
CREATE VIEW popular_item AS 
(SELECT customer_id, product_name, COUNT(product_name) AS "count", 
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) AS "pop_rank" 
FROM combined_sales 
GROUP BY customer_id, product_name);
SELECT * FROM popular_item;
-- popularity rank is successfully created
SELECT customer_id, product_name, count 
FROM popular_item 
WHERE pop_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
CREATE VIEW first_item AS 
(SELECT customer_id, product_name, MIN(order_date) as "member_date", 
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY MIN(order_date) ASC) AS "member_rank" 
FROM combined_sales
WHERE stat = 'member'
GROUP BY customer_id, product_name);
SELECT * FROM first_item;
-- order date is ranked to find out the date when a customer became a member
SELECT customer_id, member_date, product_name
FROM first_item
WHERE member_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
CREATE VIEW last_item AS 
(SELECT customer_id, product_name, order_date,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS "member_rank" 
FROM combined_sales
WHERE stat = 'non member' AND join_date IS NOT NULL);
SELECT * FROM last_item;
-- order date is ranked to find out the date when just before the customer became a member
SELECT customer_id, order_date, product_name
FROM last_item
WHERE member_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id, COUNT(DISTINCT(product_name)) AS "total items", SUM(price) AS "amount spent"
FROM combined_sales
WHERE stat = 'non member' AND join_date IS NOT NULL
GROUP BY customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, 
SUM(CASE WHEN cs.product_name = 'sushi' THEN pr*10*2 ELSE pr*10 END) AS "points"
FROM (SELECT customer_id, product_name, SUM(price) pr FROM combined_sales
GROUP BY customer_id, product_name) cs
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customers A and B have at the end of January?
CREATE VIEW points_earned AS
(SELECT customer_id, product_name, order_date, price,
join_date, DATE_ADD(join_date, INTERVAL 6 DAY) AS "fwdate",
CASE WHEN product_name = 'sushi' THEN price*2*10
WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY) THEN price*2*10
ELSE price*10 END AS "points"
FROM combined_sales);
SELECT * FROM points_earned;
-- points are calculated for each items ordered in the first week after customers joined the program
SELECT customer_id, SUM(points) AS "total points"
FROM points_earned
WHERE join_date IS NOT NULL AND order_date <= '2021-01-31'
GROUP BY customer_id;