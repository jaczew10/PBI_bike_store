



CREATE VIEW dim_customer AS
WITH customer_sales AS (
    SELECT
        c.customerid,
        c.territoryid,
        s."Name" customername,
        SUM(o.subtotal) totalsales,
        MIN(o.orderdate) firstorderdate,
        MAX(o.orderdate) lastorderdate      
    FROM
        customer c
    JOIN "StateNames.csv" s ON s."Id" = c.customerid
    JOIN orderheader o ON o.customerid = c.customerid
    GROUP BY
        c.customerid, c.territoryid, s."Name"
),
customer_orders AS (
    SELECT
        o.customerid,
        COUNT(DISTINCT o.salesorderid) orders
    FROM
        orderheader o
    GROUP BY o.customerid
),
customer_units AS (
    SELECT
        oh.customerid,
        SUM(od.orderqty) units_sold
    FROM
        orderheader oh
    JOIN orderdetail od ON od.salesorderid = oh.salesorderid
    GROUP BY oh.customerid
)
SELECT
    cs.customerid,
    cs.territoryid,
    cs.customername,
    cs.firstorderdate,
    cs.lastorderdate,
    (lastorderdate - firstorderdate) lifetimedays,
    EXTRACT(YEAR FROM AGE(lastorderdate, firstorderdate)) lifetime_years,
    cs.totalsales,
    co.orders,
    cu.units_sold,
    CASE
        WHEN co.orders >= 5 THEN 3
        WHEN co.orders >= 2 THEN 2
        WHEN co.orders = 1 THEN 1
        ELSE 0
    END AS customercategory,
    RANK() OVER (ORDER BY cs.totalsales DESC) AS rank_totalsales,
    RANK() OVER (ORDER BY co.orders DESC) AS rank_orders,
    RANK() OVER (ORDER BY cu.units_sold DESC) AS rank_units
FROM
    customer_sales cs
LEFT JOIN customer_orders co ON co.customerid = cs.customerid
LEFT JOIN customer_units cu ON cu.customerid = cs.customerid;



SELECT * FROM dim_customer;

SELECT SUM(subtotal) FROM orderheader o ;

SELECT SUM(totalsales) FROM dim_customer;



SELECT 
    c.territoryid, 
    s.regionname  AS territory_name, 
    SUM(c.totalsales) AS total_sales_per_territory
FROM 
    dim_customer c
JOIN 
    salesterritory s ON s.territoryid = c.territoryid
GROUP BY 
    c.territoryid, 
    s.regionname;



SELECT 
	(SELECT SUM(subtotal) FROM orderheader),
 	SUM(totalline)
 FROM orderdetail;


CREATE VIEW dim_product AS
WITH sales_summary AS (
    SELECT
        d.productid,
        SUM(d.orderqty) units_sold,
        SUM(d.totalline) totalsales,
        MIN(h.orderdate) first_order_date
    FROM
        orderdetail d
    JOIN
        orderheader h ON h.salesorderid = d.salesorderid
    GROUP BY
        d.productid
)
SELECT
    p.productid,
    p.productsubcategoryid,
    p.description,
    CASE 
        WHEN p.makeflag = 1 THEN 'Own Production'
        ELSE 'Purchased'
    END AS make_type,
    COALESCE(p.color, 'Not specified') color,
    COALESCE(p.sizecat, 'Not specified') size,
    p.daystomanufacture,
    p.sellstartdate,
    p.sellenddate,
    COALESCE(s.totalsales, 0) totalsales,
    COALESCE(s.units_sold, 0) units_sold,
    s.first_order_date,
    CASE 
        WHEN p.sellenddate IS NULL THEN 1
        ELSE 0
    END product_status,
    RANK() OVER (ORDER BY COALESCE(s.totalsales, 0) DESC) rank_sales,
    RANK() OVER (ORDER BY COALESCE(s.units_sold, 0) DESC) rank_units
FROM
    product p
LEFT JOIN
    sales_summary s ON s.productid = p.productid;


SELECT SUM(totalsales) FROM dim_product;


SELECT * FROM dim_product;
 