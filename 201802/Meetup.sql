--	SELECT		FROM
	-----------------

SELECT * FROM Sales.SalesOrderHeader

SELECT SalesOrderNumber, ShipDate FROM Sales.SalesOrderHeader

SELECT SalesOrderNumber as [Order Number], ShipDate as [Shipment Date] FROM Sales.SalesOrderHeader

-- then add ORDER BY ShipDate, then DESC
SELECT SalesOrderNumber as [Order Number], ShipDate as [Shipment Date] FROM Sales.SalesOrderHeader
ORDER BY ShipDate DESC
	
--	sp_help "Sales.SalesOrderHeader"
	
SELECT SalesOrderNumber, ShipDate, OnlineOrderFlag, TotalDue  FROM Sales.SalesOrderHeader
	
-- WHERE
SELECT SalesOrderNumber, ShipDate, OnlineOrderFlag
FROM Sales.SalesOrderHeader
WHERE OnlineOrderFlag = 1


-- then add ADD, and TotalDue to the SELECT
AND TotalDue > 2000

-- then add OR
SELECT SalesOrderNumber, ShipDate, OnlineOrderFlag, TotalDue
FROM Sales.SalesOrderHeader
WHERE (OnlineOrderFlag = 1 AND TotalDue > 2000) OR (OnlineOrderFlag = 0 AND TotalDue > 3000)

-- let's say we want to look at how much total we have for online vs not
-- we want to divide the data into groups then work on each group separately.

-- we can summarize what's going on in the groups. In this case we'd like to SUM.
--	GROUP BY
SELECT OnlineOrderFlag, SUM(TotalDue) as [Total Sales]
FROM Sales.SalesOrderHeader
GROUP BY OnlineOrderFlag
	
-- CASE
SELECT CASE OnlineOrderFlag  
		WHEN 0 THEN 'B&M'
		WHEN 1 THEN 'Online'
		END as SaleType,
		SUM(TotalDue) as [Total Sales]
FROM Sales.SalesOrderHeader
GROUP BY OnlineOrderFlag

-- Convert to two decimal places
SELECT CASE OnlineOrderFlag  
		WHEN 0 THEN 'B&M'
		WHEN 1 THEN 'Online'
		END as SaleType,
		CAST(SUM(TotalDue) as Decimal(18,2)) as [Total Sales]
FROM Sales.SalesOrderHeader
GROUP BY OnlineOrderFlag

-- let's say we wanted to focus in on our small sales. Say, less than $250
SELECT CASE OnlineOrderFlag  
		WHEN 0 THEN 'B&M'
		WHEN 1 THEN 'Online'
		END as SaleType,
		CAST(SUM(TotalDue) as Decimal(18,2)) as [Total Sales]
FROM Sales.SalesOrderHeader
WHERE TotalDue <= 250
GROUP BY OnlineOrderFlag
	
	
--	JOINS  -- join in product info
-- inner vs outer - DO INNER. THEN THE REST, THEN GO BACK AND MAKE IT LEFT.

-- exploring linking in SalesPerson
	-- Link in Sales Person first. Explore
	-- Link in Person
	-- Add p.last_name + ', ' + p.first_name and group by it
	-- INNER VS. LEFT. Then add ISNULL to the name

SELECT	--  p.LastName, ', ' + p.FirstName as SalesPerson
		CASE OnlineOrderFlag  
		WHEN 0 THEN 'B&M'
		WHEN 1 THEN 'Online'
		END as SaleType
		,CAST(SUM(TotalDue) as Decimal(18,2)) as [Total Sales]
FROM Sales.SalesOrderHeader soh
LEFT JOIN Sales.SalesPerson sp ON (soh.SalesPersonID = sp.BusinessEntityID)
INNER JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
GROUP BY soh.OnlineOrderFlag
-- THEN 
--GROUP BY soh.OnlineOrderFlag, p.LastName, ', ' + p.FirstName



-- HAVING - we only want to see sales people with sales greater than 10 million 
--HAVING SUM(TotalDue) > 10000000


	
--	BREAKING IT DOWN WITH "WITH"
	
-- Now let's look at July Sales for people who are in Alberta and Ontario, and let's specify
-- that we're only interested in the sales of those who have sold more than 500,000.

WITH cte_Person (BusinessEntityId, PersonName, City) AS (
SELECT p.BusinessEntityId, p.lastname + ', ' + p.FirstName, ad.City
FROM Person.Person p
INNER JOIN Person.BusinessEntity be ON (p.BusinessEntityID = be.BusinessEntityID)
INNER JOIN Person.BusinessEntityAddress be_ad ON (be_ad.BusinessEntityID = be.BusinessEntityID)
INNER JOIN Person.Address ad ON (ad.AddressID = be_ad.AddressID)
INNER JOIN Person.StateProvince sp ON (sp.StateProvinceID = ad.StateProvinceID)
WHERE sp.Name IN( 'Alberta', 'Ontario')
),
 cte_Sales (BusinessEntityId, PersonName, [Total Sales]) AS  (
SELECT	p.BusinessEntityId, 
		ISNULL(p.LastName + ', ' + p.FirstName, '') as SalesPerson
		,CAST(SUM(TotalDue) as Decimal(18,2)) as [Total Sales]
FROM Sales.SalesOrderHeader soh
LEFT JOIN Sales.SalesPerson sp ON (soh.SalesPersonID = sp.BusinessEntityID)
LEFT JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
GROUP BY 	p.BusinessEntityId, ISNULL(p.LastName + ', ' + p.FirstName, '') 	
HAVING SUM(TotalDue) > 500000
) 


SELECT * 
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesPerson sp ON (sp.BusinessEntityID = soh.SalesPersonID) 
INNER JOIN cte_Person p ON (p.BusinessEntityID = sp.BusinessEntityID)
INNER JOIN cte_Sales s ON (s.BusinessEntityId = p.BusinessEntityID)
WHERE soh.OrderDate BETWEEN '2013-Jul-01' AND '2013-Jul-31'


