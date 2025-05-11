-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 20% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.20)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
ci.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(SUM(s.total)::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2) as avg_sale_pr_cx
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC


-- Q.5
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1

	
-- -- Q.6
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities, total Monday coffee consumers in a city 
--and estimated Monday coffee consumers in 20% coffee consumers

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25), 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers,
	customers_table.unique_cx as customers_of_Monday_coffee,
	concat(round((customers_table.unique_cx/coffee_consumers)*100,4),'%') as Monday_coffee_consumers_in_total_consumers
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name


-- -- Q.7
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH t1 AS
(
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2
)

SELECT * 
FROM t1
WHERE rank <= 3


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer, avg rent per customer and avg profit from customer

-- WITH city_table AS
-- (

SELECT * FROM
(
SELECT city_name,
	   ci.estimated_rent,
	   COUNT(DISTINCT s.customer_id) as no_of_costumers,
       ROUND(SUM(s.total)::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2) as avg_sale_pr_cx,
	   ROUND(ci.estimated_rent::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2) as avg_rent_pr_cx,
			ROUND(SUM(s.total)::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2)-
	   ROUND(ci.estimated_rent::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2) AS avg_profit_pr_cx
FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci 
	ON ci.city_id = c.city_id
	GROUP BY 1,ci.estimated_rent
	order BY 1
	)
	ORDER BY avg_profit_pr_cx DESC
-- )

-- SELECT 
-- 	cr.city_name,
-- 	cr.estimated_rent,
-- 	ct.no_of_costumers,
-- 	ct.avg_sale_pr_cx,
-- 	ROUND(
-- 		cr.estimated_rent::numeric/
-- 									ct.no_of_costumers::numeric
-- 		, 2) as avg_rent_per_cx
-- FROM city as cr
-- JOIN city_table as ct
-- ON cr.city_name = ct.city_name
-- ORDER BY 4 DESC


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

SELECT * ,
  concat(ROUND(((monthly_inc - 
    LAG(monthly_inc) OVER(PARTITION BY city_name ORDER BY city_name))::numeric/
	(LAG(monthly_inc) OVER(PARTITION BY city_name ORDER BY city_name))::numeric)*100,2),'%') 
	FROM
			
        (SELECT ci.city_name,
			EXTRACT(YEAR FROM s.sale_date) AS sales_year,
			EXTRACT(MONTH FROM s.sale_date) AS sales_month,
			SUM(p.price) monthly_inc
			FROM city ci LEFT JOIN customers cu on ci.city_id=cu.city_id 
			JOIN sales s on cu.customer_id=s.customer_id 
			JOIN products p on p.product_id=s.product_id
			GROUP BY ci.city_name,EXTRACT(YEAR FROM s.sale_date),EXTRACT(MONTH FROM s.sale_date)
			ORDER BY ci.city_name
)
-- WITH
-- monthly_sales
-- AS
-- (
-- 	SELECT 
-- 		ci.city_name,
-- 		EXTRACT(MONTH FROM sale_date) as month,
-- 		EXTRACT(YEAR FROM sale_date) as YEAR,
-- 		SUM(s.total) as total_sale
-- 	FROM sales as s
-- 	JOIN customers as c
-- 	ON c.customer_id = s.customer_id
-- 	JOIN city as ci
-- 	ON ci.city_id = c.city_id
-- 	GROUP BY 1, 2, 3
-- 	ORDER BY 1, 3, 2
-- ),
-- growth_ratio
-- AS
-- (
-- 		SELECT
-- 			city_name,
-- 			month,
-- 			year,
-- 			total_sale as cr_month_sale,
-- 			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
-- 		FROM monthly_sales
-- )

-- SELECT
-- 	city_name,
-- 	month,
-- 	year,
-- 	cr_month_sale,
-- 	last_month_sale,
-- 	ROUND(
-- 		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
-- 		, 2
-- 		) as growth_ratio

-- FROM growth_ratio
-- WHERE 
-- 	last_month_sale IS NOT NULL	


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT * FROM
(
SELECT city_name,
	   SUM(s.total) as total_sales,
	   ci.estimated_rent,
	   ROUND(
	(ci.population * 0.20)/1000000, 
	2) as coffee_consumers_in_millions,
	   COUNT(DISTINCT s.customer_id) as no_of_MC_costumers,
       ROUND(SUM(s.total)::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2) as avg_sale_pr_cx,
	   ROUND(ci.estimated_rent::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2) as avg_rent_pr_cx,
			ROUND(SUM(s.total)::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2)-
	   ROUND(ci.estimated_rent::numeric/
			 COUNT(DISTINCT s.customer_id)::numeric
			    ,2) AS avg_profit_pr_cx
FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci 
	ON ci.city_id = c.city_id
	GROUP BY 1,ci.estimated_rent,4
	order BY 1
	)
	ORDER BY 2 DESC


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
