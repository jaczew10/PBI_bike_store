









CREATE VIEW sales_territory AS
SELECT 
	s.territoryid,
	s.regionname, 
	s.regioncode,
	s.groupname,
	SUM(o.totaldue) totalrevenue,
	SUM(o.subtotal) totalsales,
	SUM(CASE WHEN o.orderdate >= '2014-01-01' THEN o.subtotal ELSE 0 END) sales_ytd,
	SUM(o.taxamt) taxamt,
	sum(o.freight) freight,
	COUNT(DISTINCT(o.customerid)) customerqty,
	SUM(od.orderqty) unitsold
FROM salesterritory s
JOIN orderheader o ON o.territoryid = s.territoryid
JOIN orderdetail od ON od.salesorderid = o.salesorderid
GROUP BY 
	s.territoryid,
	s.regionname, 
	s.regioncode,
	s.groupname;


SELECT * FROM sales_territory s;

SELECT * FROM salesteam s;


	
	

CREATE VIEW sales_team AS
SELECT
  s.businessentityid AS salespersonid,
  CASE
    WHEN s.territoryid::TEXT ~ '^\d+$' THEN s.territoryid::INTEGER
    ELSE NULL
  END AS territoryid,
  CASE
    WHEN s.salesquota::TEXT ~ '^\d+$' AND s.salesquota::INTEGER = 300000 THEN 3000000
    WHEN s.salesquota::TEXT ~ '^\d+$' AND s.salesquota::INTEGER = 250000 THEN 2500000
    WHEN s.salesquota::TEXT ~ '^\d+$' THEN s.salesquota::INTEGER
    ELSE NULL
  END AS salesquota,
  CASE
    WHEN s.bonus::TEXT ~ '^\d+$' THEN s.bonus::INTEGER
    ELSE NULL
  END AS bonus,
  CASE 
    WHEN s.commissionpct::TEXT ~ '^\d+(,\d+)?$' THEN 
      REPLACE(s.commissionpct::TEXT, ',', '.')::NUMERIC(5,4)
    ELSE NULL
  END AS commissionpct,
  sn."Name" AS salesperson_name,
  sa.firstorderdate AS firstorderdate,
  CASE
    WHEN s.territoryid::TEXT ~ '^\d+$' AND s.territoryid::INTEGER <> 0 THEN 1
    ELSE 0
  END AS contractid,
  sa.totalsales,
  sa.sales_ytd,
  sa.sales2013,
  sa.sales2012,
  sa.sales2011,
  ROUND(sa.totalsales * 
        REPLACE(s.commissionpct::TEXT, ',', '.')::NUMERIC(4,3), 2) AS totalcommission,
  ROUND(sa.sales_ytd * 
        REPLACE(s.commissionpct::TEXT, ',', '.')::NUMERIC(4,3), 2) AS commission_ytd,
  ROUND(sa.sales2013 * 
        REPLACE(s.commissionpct::TEXT, ',', '.')::NUMERIC(4,3), 2) AS commission2013,
  ROUND(sa.sales2012 * 
        REPLACE(s.commissionpct::TEXT, ',', '.')::NUMERIC(4,3), 2) AS commission2012,
  ROUND(sa.sales2011 * 
        REPLACE(s.commissionpct::TEXT, ',', '.')::NUMERIC(4,3), 2) AS commission2011,
  ROUND(
    CASE
      WHEN s.salesquota::TEXT ~ '^\d+$' AND 
           (
             s.salesquota::INTEGER = 250000 OR 
             s.salesquota::INTEGER = 300000
           )
      THEN 
        sa.sales_ytd / 
        (
          CASE 
            WHEN s.salesquota::INTEGER = 300000 THEN 3000000
            WHEN s.salesquota::INTEGER = 250000 THEN 2500000
            ELSE s.salesquota::INTEGER
          END
        ) * 100
      ELSE 0
    END, 2
  ) AS targetachievement
FROM salesteam s
JOIN (
  SELECT businessentityid, ROW_NUMBER() OVER (ORDER BY businessentityid) AS nameid
  FROM salesteam
) r ON r.businessentityid = s.businessentityid
LEFT JOIN "StateNames.csv" sn ON sn."Id" = r.nameid
LEFT JOIN (
  SELECT 
    salespersonid,
    SUM(subtotal) AS totalsales,
    SUM(CASE WHEN orderdate >= '2014-01-01' THEN subtotal ELSE 0 END) AS sales_ytd,
    SUM(CASE WHEN orderdate BETWEEN '2013-01-01' AND '2013-12-31' THEN subtotal ELSE 0 END) AS sales2013,
    SUM(CASE WHEN orderdate BETWEEN '2012-01-01' AND '2012-12-31' THEN subtotal ELSE 0 END) AS sales2012,
    SUM(CASE WHEN orderdate BETWEEN '2011-01-01' AND '2011-12-31' THEN subtotal ELSE 0 END) AS sales2011,
    MIN(orderdate) AS firstorderdate
  FROM orderheader
  GROUP BY salespersonid
) sa ON sa.salespersonid = s.businessentityid;


	
	
	
	



