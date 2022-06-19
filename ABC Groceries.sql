SELECT *
FROM [Porfolio Projects].dbo.Customer_Raw$

SELECT *
FROM [Porfolio Projects].dbo.Transaction_raw$

SELECT *
FROM [Porfolio Projects].dbo.Location_raw$

--(1) Check number of rows for each table and check if any missing values
SELECT count(*), count(ACCOUNT_NUMBER), count(GENDER), count(MY_SHOPPING),count(COALITION_SEGMENT)
FROM [Porfolio Projects].dbo.Customer_Raw$

SELECT count(*), count(TRAN_KEY), count(ACCOUNT_NUMBER), count(TRAN_SPEND), count(text_month), count(number_year), count(DATE_MONTHLY), count(LOCATION_CODE)
FROM [Porfolio Projects].dbo.Transaction_raw$

SELECT count(*), count(LOCATION_CODE), count(STORE_TYPE), count(REGION), count(ZONE)
FROM [Porfolio Projects].dbo.Location_raw$
--No missing value PERFECT!

--(2)use transaction table as main table, left join other two tables, and create a temp table #abc
--create a new column has date as datatype for later aggregation

SELECT TRAN_KEY,TRAN_SPEND,text_month, number_year, DATE_MONTHLY,c.*, l.*, CAST(CONCAT(text_month,' 01',' ',CAST(number_year as varchar))as date) as date_right
INTO #abc
FROM [Porfolio Projects].dbo.Transaction_raw$ AS t
LEFT JOIN [Porfolio Projects].dbo.Customer_Raw$ AS c
ON t.ACCOUNT_NUMBER =c.ACCOUNT_NUMBER
LEFT JOIN [Porfolio Projects].dbo.Location_raw$ AS l
ON t.LOCATION_CODE = l.LOCATION_CODE
WHERE TRAN_KEY is not null;


--(3) [CHART1] calculate monthly total sales, number of transactions, number of customers and number of unique customers
SELECT date_right as Transaction_Date, SUM(TRAN_SPEND) as Total_Sale , COUNT(TRAN_KEY) as Total_Transactions, COUNT(ACCOUNT_NUMBER) as Number_customers, 
count(DISTINCT ACCOUNT_NUMBER) as unique_customers
FROM #abc
GROUP BY date_right
ORDER BY date_right

--(4) AVERAGE SALE per transaction per month
SELECT date_right as Transaction_Date, ROUND(SUM(TRAN_SPEND)/count(TRAN_KEY),2) AS Avg_Sale_per_Tran
FROM #abc
GROUP BY date_right

--(5) [CHART 2] Average Sale per Transaction per year
SELECT number_year as Tran_Year, ROUND(SUM(TRAN_SPEND)/count(TRAN_KEY),2) AS Avg_Sale_per_Tran
FROM #abc
GROUP BY number_year
ORDER BY number_year

--(6) [CHART 3] check stores information
--how many distinct zone for region 5
SELECT COUNT(DISTINCT ZONE)
FROM #abc

--how many store types in this region
SELECT COUNT(DISTINCT STORE_TYPE)
FROM #abc

--how many stores for each store type in each zone
SELECT ZONE, STORE_TYPE, COUNT(DISTINCT LOCATION_CODE)
FROM #abc
GROUP BY ZONE,STORE_TYPE
ORDER BY ZONE,STORE_TYPE 

--(7) [CHART4] what is the total sales by zone
SELECT ZONE, ROUND(sum(TRAN_SPEND),2) as Total_Sales
FROM #abc
GROUP BY ZONE

--(8) [CHART5](the average sale per transaction for each store order by zone and store_type
SELECT ZONE, STORE_TYPE,LOCATION_CODE, ROUND(sum(TRAN_SPEND)/COUNT(TRAN_KEY),2)as avg_sale_tran
FROM #abc
GROUP BY ZONE, STORE_TYPE,LOCATION_CODE
ORDER BY ZONE, STORE_TYPE

--(9)[CHART6] how about customer segmentation? group by gender
SELECT GENDER, COUNT(GENDER)as Number
FROM #abc
GROUP  BY GENDER

SELECT *
FROM #abc

--(10)[CHART7] what is the avg sale per transaction grouped by customer retailer's segmentation
SELECT number_year, MY_SHOPPING, sum(TRAN_SPEND) as Total_Sales, count(TRAN_KEY) as Num_Trans, ROUND(sum(TRAN_SPEND)/count(TRAN_KEY),2)  as Avg_Sale_Tran
FROM #abc
GROUP BY number_year, [MY_SHOPPING ]
ORDER BY number_year, [MY_SHOPPING ]

--(11)[CHART8] how about the info for coalition customer segmentation
SELECT number_year, COALITION_SEGMENT, sum(TRAN_SPEND) as Total_Sales, count(TRAN_KEY) as Num_Trans, ROUND(sum(TRAN_SPEND)/count(TRAN_KEY),2)  as Avg_Sale_Tran
FROM #abc
GROUP BY number_year, COALITION_SEGMENT
ORDER BY number_year, COALITION_SEGMENT

--(12) want to check do we have returning customers? and how frequently do they shop?
--how many customers have come into the stores?
SELECT count(TRAN_KEY)
FROM #abc
--how many distint customer do we have?
SELECT COUNT(DISTINCT ACCOUNT_NUMBER)
FROM #abc

--the frequency of shopping for each customer
SELECT ACCOUNT_NUMBER, count(ACCOUNT_NUMBER) AS Times_shopping
FROM #abc
GROUP BY ACCOUNT_NUMBER

SELECT ACCOUNT_NUMBER, number_year, date_right, count(ACCOUNT_NUMBER) AS Times_shopping, AVG(TRAN_SPEND) as AVG_SPENT
FROM #abc
GROUP BY number_year, date_right, ACCOUNT_NUMBER
ORDER BY ACCOUNT_NUMBER, number_year, date_right
--answer: 600 distinct customers, each of time visited abc groceries once per month, and vistied every single month

--did they visit the same store location?
SELECT ACCOUNT_NUMBER, LOCATION_CODE, STORE_TYPE, date_right
FROM #abc
ORDER BY ACCOUNT_NUMBER, date_right
--answer: they all visited the same store for every single time

--[CHART9] frequency of shopping vs number of customers
SELECT Times_shopping, count(ACCOUNT_NUMBER) AS number_customers
FROM
    (SELECT ACCOUNT_NUMBER, count(ACCOUNT_NUMBER) AS Times_shopping
     FROM #abc
     GROUP BY ACCOUNT_NUMBER) AS cus_shop
GROUP BY Times_shopping
ORDER BY Times_shopping

--how many new customer for the first month after store open
SELECT COUNT(DISTINCT ACCOUNT_NUMBER) as new_customers
FROM #abc
WHERE date_right='2012-04-01'

--check new customers for 2012 May
SELECT COUNT(DISTINCT ACCOUNT_NUMBER) as new_customers
FROM #abc
WHERE date_right='2012-05-01'
AND ACCOUNT_NUMBER not IN (
   SELECT DISTINCT ACCOUNT_NUMBER 
   FROM #abc
   WHERE date_right='2012-04-01')
--results: no new customer, all existing 510 customers come back this month again

SELECT COUNT(DISTINCT ACCOUNT_NUMBER) as new_customers
FROM #abc
WHERE date_right='2013-04-01'
AND ACCOUNT_NUMBER not IN (
   SELECT DISTINCT ACCOUNT_NUMBER 
   FROM #abc
   WHERE date_right='2012-04-01')
-- 90 new customers emerge because of three grandly opened convenience store

