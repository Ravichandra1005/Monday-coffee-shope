	-- creating tables 
	create table city(
	city_id int primary key,
	city_name varchar(20),
	population bigint,
	estimated_rent float,
	city_rank int
	);
	
	create table customers(
	customer_id int primary key,
	customer_name varchar(25),
	city_id int,
	constraint fk_city foreign key (city_id) references city(city_id));
	
	
	create table products(
	product_id int primary key,
	product_name varchar(100),
	price float);
	
	create table sales(
	sale_id int primary key,
	sale_date date,
	product_id int,
	customer_id int,
	total float,
	rating varchar(10),
	constraint fk_products foreign key (product_id) references products(product_id),
	constraint fk_customers foreign key (customer_id) references customers(customers_id));
	
	-- import data
	select * from city;
	select * from customers;
	select * from products;
	select * from sales;
	
	--reports on data analyst
	-- Key Questions
	-- Coffee Consumers Count
	-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
	
	select city_name,population*0.25 as coffee_consumer ,city_rank
	from city
	order by city_rank desc;
	
	
	-- Total Revenue from Coffee Sales
	-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
	
	SELECT SUM(total) AS total_revenue_q4_2023
	FROM sales
	WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31';
	
	-- Sales Count for Each Product
	-- How many units of each coffee product have been sold?
	
	SELECT
	    p.product_id,
	    p.product_name,
	    COUNT(s.sale_id) AS total_units_sold
	FROM products as p
	LEFT JOIN sales as s
	ON p.product_id = s.product_id
	GROUP BY p.product_id, p.product_name
	ORDER BY total_units_sold DESC;
	
	-- Average Sales Amount per City
	-- What is the average sales amount per customer in each city?
	SELECT
	    ct.city_id,
	    ct.city_name,
	    AVG(customer_total) AS avg_sales_per_customer
	FROM (
	    SELECT
	        s.customer_id,
	       SUM(s.total) AS customer_total
	    FROM sales s
	    GROUP BY s.customer_id
	) AS customer_sales
	JOIN customers c ON customer_sales.customer_id = c.customer_id
	JOIN city ct ON c.city_id = ct.city_id
	GROUP BY ct.city_id, ct.city_name
	ORDER BY avg_sales_per_customer DESC;
	
	
	-- City Population and Coffee Consumers
	-- Provide a list of cities along with their populations and estimated coffee consumers.
	
	SELECT city_name,population,population * 0.4 AS estimated_coffee_consumers  
	FROM city;
	
	-- Top Selling Products by City
	-- What are the top 3 selling products in each city based on sales volume?
	
	SELECT * 
	FROM -- table
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
		-- ORDER BY 1, 3 DESC
	) as t1
	WHERE rank <= 3
	
	-- Customer Segmentation by City
	-- How many unique customers are there in each city who have purchased coffee products?
	
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM city as ci
	LEFT JOIN
	customers as c
	ON c.city_id = ci.city_id
	JOIN sales as s
	ON s.customer_id = c.customer_id
	WHERE 
		s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
	GROUP BY 1;
	
	
	-- Average Sale vs Rent
	-- Find each city and their average sale per customer and avg rent per customer
	
	WITH city_table
	AS
	(
		SELECT 
			ci.city_name,
			SUM(s.total) as total_revenue,
			COUNT(DISTINCT s.customer_id) as total_cx,
			ROUND(
					SUM(s.total)::numeric/
						COUNT(DISTINCT s.customer_id)::numeric
					,2) as avg_sale_pr_cx
			
		FROM sales as s
		JOIN customers as c
		ON s.customer_id = c.customer_id
		JOIN city as ci
		ON ci.city_id = c.city_id
		GROUP BY 1
		ORDER BY 2 DESC
	),
	city_rent
	AS
	(SELECT 
		city_name, 
		estimated_rent
	FROM city
	)
	SELECT 
		cr.city_name,
		cr.estimated_rent,
		ct.total_cx,
		ct.avg_sale_pr_cx,
		ROUND(
			cr.estimated_rent::numeric/
										ct.total_cx::numeric
			, 2) as avg_rent_per_cx
	FROM city_rent as cr
	JOIN city_table as ct
	ON cr.city_name = ct.city_name
	ORDER BY 4 DESC;
	
	
	-- Monthly Sales Growth
	-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
	
	WITH
	monthly_sales
	AS
	(
		SELECT 
			ci.city_name,
			EXTRACT(MONTH FROM sale_date) as month,
			EXTRACT(YEAR FROM sale_date) as YEAR,
			SUM(s.total) as total_sale
		FROM sales as s
		JOIN customers as c
		ON c.customer_id = s.customer_id
		JOIN city as ci
		ON ci.city_id = c.city_id
		GROUP BY 1, 2, 3
		ORDER BY 1, 3, 2
	),
	growth_ratio
	AS
	(
			SELECT
				city_name,
				month,
				year,
				total_sale as cr_month_sale,
				LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
			FROM monthly_sales
	)
	
	SELECT
		city_name,
		month,
		year,
		cr_month_sale,
		last_month_sale,
		ROUND(
			(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
			, 2
			) as growth_ratio
	
	FROM growth_ratio
	WHERE 
		last_month_sale IS NOT NULL	;
	
	-- Market Potential Analysis
	-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
	
	WITH city_table
	AS
	(
		SELECT 
			ci.city_name,
			SUM(s.total) as total_revenue,
			COUNT(DISTINCT s.customer_id) as total_cx,
			ROUND(
					SUM(s.total)::numeric/
						COUNT(DISTINCT s.customer_id)::numeric
					,2) as avg_sale_pr_cx
			
		FROM sales as s
		JOIN customers as c
		ON s.customer_id = c.customer_id
		JOIN city as ci
		ON ci.city_id = c.city_id
		GROUP BY 1
		ORDER BY 2 DESC
	),
	city_rent
	AS
	(
		SELECT 
			city_name, 
			estimated_rent,
			ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
		FROM city
	)
	SELECT 
		cr.city_name,
		total_revenue,
		cr.estimated_rent as total_rent,
		ct.total_cx,
		estimated_coffee_consumer_in_millions,
		ct.avg_sale_pr_cx,
		ROUND(
			cr.estimated_rent::numeric/ct.total_cx::numeric
			, 2) as avg_rent_per_cx
	FROM city_rent as cr
	JOIN city_table as ct
	ON cr.city_name = ct.city_name
	ORDER BY 2 DESC;

