Query 1) Based on the discount, count how many orders were placed?

Answer) 
select i.discount, count(*) as count_orders from sales.order_items  i 
join sales.orders o
on i.order_id = o.order_id
group by i.discount
order by 2 desc


Query 2) Create net sales report of staff for every month. Take the year as input.

Answer)

CREATE VIEW sales.stores_netsales
AS
	SELECT 
		s.store_name, 
		f.first_name,
		MONTH(o.order_date) month, 
		YEAR(o.order_date) year, 
		CONVERT(DEC(10, 0), SUM((i.list_price * i.quantity) * (1 - i.discount))) AS net_sales
	FROM sales.orders AS o
		INNER JOIN sales.order_items AS i ON i.order_id = o.order_id
		INNER JOIN sales.staffs AS f ON f.staff_id = o.staff_id
		INNER JOIN sales.stores AS s ON s.store_id = o.store_id
	GROUP BY s.store_name, f.first_name,
			MONTH(o.order_date), 
			YEAR(o.order_date);

CREATE PROCEDURE getSalesReport(@year AS INT)
AS
	BEGIN
		WITH sales_report AS (
			SELECT 
				month,
				first_name,
				net_sales,
				LAG(net_sales,1) OVER (
					PARTITION BY first_name
					ORDER BY month
				) previous_sales
			FROM 
				sales.stores_netsales
			WHERE
				year = @year
		)
		SELECT 
			month, 
			first_name,
			net_sales, 
			previous_sales,
			FORMAT(
				(net_sales - previous_sales)  / previous_sales,
				'P'
			) vs_previous_month
		FROM
			sales_report;

END;

EXEC getSalesReport 2017;


Query 3) Rank the stores based on the net sales

Answer)
select store_name, rank() over (order by sum(net_sales) desc) as rank,
sum(net_sales) as total from sales.stores_netsales
group by store_name
