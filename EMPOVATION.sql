----Count of Orders PER Person
SELECT TOP 10 Name, COUNT ([Order Number]) as TotalOrders
FROM Sales
JOIN Customers
  ON Sales.CustomerKey = Customers.CustomerKey
  GROUP BY Name
  ORDER BY TotalOrders DESC
 

----------------------------------------------------------------------------------------------------------------------------------

---LIST OF PRODUCTS IN 2020
 SELECT *
 FROM Products

 SELECT *
 FROM Sales$

 ALTER TABLE SALES$
 ALTER COLUMN Year_OrderDate date null
 
 SELECT YEAR (Year_OrderDate) as OrderYear
 FROM Sales$

  ALTER TABLE SALES$
 ALTER COLUMN OrderYear NVARCHAR (255) null

 UPDATE SALES$
 SET OrderYear =YEAR (Year_OrderDate)

 SELECT [Product Name], OrderYear,  SUM (Quantity) AS [Total Quantity Sold]
 FROM Sales$
 JOIN Products
 ON Sales$.ProductKey = Products.ProductKey
 WHERE OrderYear = 2020
 GROUP BY [Product Name], OrderYear
 Order By [Total Quantity Sold] DESC

--------------------------------------------------------------------------------------------------------------

 ---CUSTOMERS DETAILS FROM CALIFORNIA
 SELECT Name, Birthday, Gender, Country, State, City
 FROM Customers
 WHERE State = 'California'
 --Order By Birthday DESC

----------------------------------------------------------------------------------------------------------------------------

 ---Total Sales Quantity For Product Number 2115
 SELECT P.ProductKey, [Product Name], OrderYear, Sum (Quantity) as [Total Quantity]
 FROM Sales$ S
 JOIN Products P
 ON S.ProductKey  = P.ProductKey 
 WHERE P.ProductKey = 2115
 GROUP BY P.ProductKey, [Product Name], OrderYear
 ORDER BY [Total Quantity] DESC

 
-----------------------------------------------------------------------------------------------------------------------------

 --- TOP 5 STORES WITH THE MOST SALES TRANSACTIONS
 ----------Removing the $ sign to aid calculation and converting money
 SELECT Quantity, [Unit Price USD], CAST(REPLACE([Unit Price USD], '$', ' ') AS money) UnitPrice
  FROM Products P
 JOIN Sales$    S
 ON P.ProductKey = S.ProductKey

 ALTER TABLE Products 
 ADD UnitPrice Money Null

 UPDATE Products
 SET UnitPrice = CAST(REPLACE([Unit Price USD], '$', ' ') AS money)

 SELECT *
 FROM Products

 ---Calculating the top 5 stores withthe most transactions
 SELECT StoreKey, sum(Quantity) Total_Quantity, sum(TotalPrice) GrandPrice
 from(
 SELECT ST.StoreKey,Quantity, [Unit Price USD], P.UnitPrice,
		(Quantity*P.UnitPrice) TotalPrice
  FROM Products P
 JOIN Sales$    S
 ON S.ProductKey = P.ProductKey
 JOIN Stores    ST
 ON  S.StoreKey = ST.StoreKey
 GROUP BY Quantity, [Unit Price USD], ST.StoreKey, P.UnitPrice
 --ORDER BY TotalPrice DESC
 ) AS Total_Transactions
 GROUP BY StoreKey
 ORDER BY GrandPrice DESC

--------------------------------------------------------------------------------------------------------

 ----AVERAGE PRICE OF PRODUCT IN A CATEGORY
 SELECT CategoryKey,
		Category, 
		AVG (UnitPrice) as [Average Unit Price]
 FROM Products
 GROUP BY Category,CategoryKey

 

 ---------------------------------------------------------------------------------------------------------
 --- Customer Purchases by Gender
SELECT Gender, COUNT (DISTINCT [Order Number]) as [Total Purchase Made], COUNT(Gender) as [Gender Total]
FROM Customers C
JOIN Sales$ S
    ON C.CustomerKey = S.CustomerKey
GROUP BY Gender


---------------------------------------------------------------------------------------------------------------------------

----List Of Product not Sold (Using TEMP TABLE)
-----First is to create a temp table that contains the products sold
CREATE TABLE #temp_Products_Sold
(
ProductKey float null,
[product Name] nvarchar (255)  null
)
ALTER TABLE #temp_Products_Sold
ADD Category nvarchar (255)  null 

----Inserting Values into Temp Table
INSERT INTO #temp_Products_Sold 
SELECT Sales$.ProductKey ,[Product Name], Category
FROM Sales$
JOIN
Products
on Sales$.ProductKey = Products.ProductKey

---Getting the list of products not sold
SELECT ProductKey, [Product Name] as [Products Not Sold], Category
FROM Products
EXCEPT
SELECT ProductKey, [Product Name], Category
from #temp_Products_Sold
Order by [Products Not Sold]

----Taking the list of products not sold and locking it in a temp table to further group it.
CREATE TABLE #temp_Products_NotSold
(
ProductKey float null,
[product Not Sold] nvarchar (255)  null,
Category nvarchar (255)  null
)
INSERT INTO #temp_Products_NotSold
SELECT ProductKey, [Product Name] as [Products Not Sold], Category
FROM Products
EXCEPT
SELECT ProductKey, [Product Name], Category
from #temp_Products_Sold
Order by [Products Not Sold]

----Counting the values in each category
SELECT Category, COUNT(Category)as [Total quantity not sold]
FROM #temp_Products_NotSold
GROUP BY Category

----Comparing the quantity sold vs quantity not sold wrt category values

SELECT 
    COALESCE(ns.Category, s.Category) AS Category,
    COALESCE(ns.TotalNotSold, 0) AS [Total Quantity Not Sold],
    COALESCE(s.TotalSold, 0) AS [Total Quantity Sold]
FROM 
    (SELECT Category, COUNT(*) AS TotalNotSold
     FROM #temp_Products_NotSold 
     GROUP BY Category) ns
FULL OUTER JOIN 
    (SELECT Category, COUNT(*) AS TotalSold
     FROM #temp_Products_Sold 
     GROUP BY Category) s
ON ns.Category = s.Category;

--GROUP BY Category
SELECT Category, COUNT(Category)as [Total quantity not sold]
FROM #temp_Products_Sold
GROUP BY Category



---------------------------------------------------------------------------------------------------------------
-----Currency Conversion for Orders
SELECT *
FROM Exchange_Rates

SELECT ([Currency Code])
FROM Sales$

------------------------------------------------------------------------------------------------------------
---CUSTOMER SEGMENTATION BY PURCHASE BEHAVIOUR AND DEMOGRAPHICS

--BY GENDER
SELECT Gender, COUNT([Order Number]) as [Total Orders]
FROM Sales$ S
JOIN
	Customers C
	ON S.CustomerKey =C.CustomerKey
GROUP BY Gender
ORDER BY Gender


--BY STATE
--(1 WAY) 
SELECT [Order Number], State, Category, COUNT([Order Number]) OVER (PARTITION BY [Order Number])as [Total Orders] 
FROM Sales$	S
JOIN
     Customers  C
	 ON C.CustomerKey = S.CustomerKey
JOIN
	Products P
	ON  S.ProductKey = P.ProductKey
	ORDER BY State

--(2nd Way)
	SELECT State, COUNT(DISTINCT[Order Number]) as [Total Orders] 
FROM Sales$	S
JOIN
     Customers  C
	 ON C.CustomerKey = S.CustomerKey
JOIN
	Products P
	ON  S.ProductKey = P.ProductKey
	GROUP BY State
	ORDER BY [Total Orders]DESC

--BY AGE
		---CONVERTING "BIRTHDAY" FROM NVARCHAR TO DATETIME AND UPDATING THE CUSTOMERS TABLE TO REFLECT THE CHANGE
SELECT CAST("Birthday" AS DATETIME) ConvertedBirthday
FROM Customers

ALTER TABLE Customers
ADD ConvertedBirthday DATETIME NULL

UPDATE Customers
SET ConvertedBirthday = CAST("Birthday" AS DATETIME)

	----EXTRACTING THE YEAR FROM THE CONVERTEDBIRTHDAY
SELECT YEAR(ConvertedBirthday) as BirthYear
FROM Customers

ALTER TABLE Customers
ADD BirthYear INT NULL

ALTER TABLE Customers
ALTER COLUMN BirthYear INT NOT NULL

UPDATE Customers
SET BirthYear = YEAR(ConvertedBirthday)

-----CALCULATING THE AGE OF CUSTOMERS AS AT THE YEAR ORDERS WERE PLACED BY CUSTOMERS
SELECT BirthYear
FROM Customers

SELECT OrderYear
FROM Sales$
 
ALTER TABLE Customers
ADD Customer_Age INT NULL

UPDATE Customers
SET Customer_Age = (OrderYear - BirthYear ) 
FROM Customers C
JOIN Sales$    S
      ON  	C. CustomerKey = S.CustomerKey

	  SELECT *
	  FROM Customers
	  --ALTER TABLE Customers
	  --ALTER COLUMN Customer_Age INT NOT NULL

											---OR

---CALCULATING THE DATE DIFFERENCE BETWEEN THE CONVERTEDBIRTHDAY AND THE ORDERYEAR TO GET THE CUSTOMERS AGE AS AT THE TIME THE ORDER WAS PLACED
SELECT DATEDIFF(yyyy, "ConvertedBirthday","Year_OrderDate") AS CustomerAge
FROM Customers C
JOIN Sales$    S
      ON  	C. CustomerKey = S.CustomerKey


ALTER TABLE Customers
ADD CustomerAge Int Null

UPDATE Customers
SET CustomerAge =  DATEDIFF(yyyy, "ConvertedBirthday","Year_OrderDate")
FROM Customers C
JOIN Sales$    S
      ON  	C. CustomerKey = S.CustomerKey

	  --CLASSIFICATION OF CUSTOMERS AGE 
SELECT Customer_age,
CASE	WHEN Customer_Age BETWEEN 14 and 19 THEN 'Teenager'
		WHEN Customer_Age BETWEEN 20 and 40 THEN 'Youth'
		WHEN Customer_Age BETWEEN 41 and 59 THEN 'Elder'
		WHEN Customer_Age BETWEEN 60 and 90 THEN 'Senior'
		ELSE 'NOT Grouped'
		END
from Customers

ALTER TABLE Customers
ADD [Age Classification] nvarchar (255) NULL

UPDATE Customers
SET [Age Classification] =
CASE	WHEN Customer_Age BETWEEN 14 and 19 THEN 'Teenagers'
		WHEN Customer_Age BETWEEN 20 and 40 THEN 'Youths'
		WHEN Customer_Age BETWEEN 41 and 59 THEN 'Elders'
		WHEN Customer_Age BETWEEN 60 and 90 THEN 'Seniors'
		ELSE 'NOT Grouped'
		END

---CUSTOMER SEGMENTATION BY AGE 
SELECT [Age Classification], Category, COUNT (Category) as TotalOrders
--COUNT (Category) OVER (PARTITION BY Category) AS TotalProductsPurchased
FROM Sales$	S
JOIN
     Customers  C
	 ON C.CustomerKey = S.CustomerKey
JOIN
	Products P
	ON  S.ProductKey = P.ProductKey
	GROUP BY [Age Classification], Category
	ORDER BY TotalOrders DESC
	--GROUP BY [Age Classification]
	--ORDER BY [Total Orders]DESC

SELECT *
FROM Customers
SELECT *
FROM Sales$

----------------------------------------------------------------------------------------------------------------------------------------


  -----Impact of Store Size on Sales Volume
 ---CONVERTING [UNIT PTRICE USD] TO MONEY AND UPDATING
  
  ALTER TABLE Sales$
  ADD UnitPrice money null

  UPDATE Sales$
  SET UnitPrice = CAST(REPLACE([Unit Price USD], '$', ' ') AS money)
  FROM Products P
 JOIN Sales$    S
 ON P.ProductKey = S.ProductKey

 --REPLACING STORE IDs WITH COUNTRY AS ONLINE WITH 'O' AS SQUARE METER
  SELECT REPLACE([Square Meters], ' ', '0')
  FROM Stores ST
  join Sales$ SA
  ON ST.StoreKey = SA.StoreKey
  WHERE Country = 'Online'

----GROUPING STORES INTO CATEGORIES BASED ON SQUARE METER
ALTER TABLE Stores
ADD [Store Category] nvarchar (255) NULL

  UPDATE Stores
  SET [Store Category] = CASE	When [Square Meters]  >= 1000 Then 'Large Store'
								When [Square Meters] IS NULL Then 'Online Store'
								Else 'Small Store'
						 END 


 SELECT [Store Category],SUM (UnitPrice) [Total Sold]
  FROM Stores ST
  join Sales$ SA
  ON ST.StoreKey = SA.StoreKey
  GROUP BY [Store Category]
  ORDER BY SUM(UnitPrice) DESC

-------RANKINGSTORES BY SALES VOLUME
SELECT ST.StoreKey,[Store Category], SUM (UnitPrice) [Total Sold],
		RANK() OVER (ORDER BY SUM (UnitPrice) DESC) [Store Rank]
  FROM Stores ST
  join Sales$ SA
  ON ST.StoreKey = SA.StoreKey
  GROUP BY [Store Category], ST.StoreKey
  --ORDER BY[Total Sold]

  
----RUNNING TOTAL SALES OVER TIME
SELECT Category, Year_OrderDate,S.UnitPrice, SUM (S.UnitPrice)OVER (ORDER BY Year_OrderDate)as [Running Total]
FROM Sales$ S
JOIN
Products P
ON 
S.ProductKey= P.ProductKey
GROUP  BY Year_OrderDate, S.UnitPrice, Category


---LIFE TIME VALUE OF CUSTOMERS
WITH CustomerPurchases AS (
    SELECT 
        C.CustomerKey, YEAR(S.Year_OrderDate) as SalesYear,
        COUNT(S.[Order Number]) AS PurchaseCount,
        SUM(S.UnitPrice) AS TotalSpent
    FROM 
        Customers C
    JOIN 
        Sales$ S ON C.CustomerKey = S.CustomerKey
    GROUP BY 
        C.CustomerKey, YEAR(S.Year_OrderDate)),
Metrics AS (
    SELECT 
	    SalesYear,
        AVG(TotalSpent) AS AveragePurchaseValue,
        AVG(PurchaseCount) AS PurchaseFrequency
    FROM 
        CustomerPurchases
	GROUP BY 
			SalesYear)
SELECT 
	 SalesYear,
    (AveragePurchaseValue * PurchaseFrequency * EstimatedCustomerLifespan) AS CustomerLifetimeValue
FROM 
    Metrics,
    (SELECT 3 AS EstimatedCustomerLifespan) AS Lifespan;  

----LIFE TIME VALUE OF CUSTOMERS BY COUNTRY 
WITH 
	CustomerPurchases AS (
    SELECT 
        C.CustomerKey, Country,
        COUNT(S.[Order Number]) AS PurchaseCount,
        SUM(S.UnitPrice) AS TotalSpent
    FROM 
        Customers C
    JOIN 
        Sales$ S ON C.CustomerKey = S.CustomerKey
    GROUP BY 
        C.CustomerKey, Country),
Metrics AS (
    SELECT 
	    Country,
        AVG(TotalSpent) AS AveragePurchaseValue,
        AVG(PurchaseCount) AS PurchaseFrequency
    FROM 
        CustomerPurchases
	GROUP BY 
			Country)
SELECT 
	 Country,
    (AveragePurchaseValue * PurchaseFrequency * EstimatedCustomerLifespan) AS CustomerLifetimeValue
FROM 
    Metrics,
    (SELECT 3 AS EstimatedCustomerLifespan) AS Lifespan; 
  

----TOTAL SALES TREND
SELECT Category,OrderYear, SUM (Quantity) TotalQuantity, Sum(TotalPrice) TotalSalesPrice 
FROM(
SELECT Quantity,P.UnitPrice,OrderYear,
		(Quantity*P.UnitPrice) TotalPrice, Category
  FROM Products P
 JOIN Sales$    S
 ON S.ProductKey = P.ProductKey
 JOIN Stores    ST
 ON  S.StoreKey = ST.StoreKey
 GROUP BY Quantity,P.UnitPrice,OrderYear, Category) AS Trend
 GROUP BY Category, OrderYear
 ORDER BY OrderYear DESC

SELECT *
FROM Products
SELECT *
FROM Sales$