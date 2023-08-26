use AdventureWorks2019
go
/* שאלה 2
select * from Sales.Customer c where c.LastName = 'Duffy'
select * from Person.Person p where p.LastName = 'Duffy'
select * from Sales.SalesOrderHeader s where s.CustomerID = 2
select * from Sales.SalesOrderDetail sod where sod.OrderQty = 0
select * from Production.Product

select count(soh.CustomerID)
from Sales.SalesOrderHeader soh
join Sales.Customer c on c.CustomerID = soh.CustomerID
where soh.CustomerID = 29672

*/

--QUESTION 1
select p.ProductID ,p.Name , p.Color , p.ListPrice , p.Size 
from Sales.SalesOrderDetail sod
right join Production.Product p on p.ProductID = sod.ProductID
where sod.SalesOrderID is null
order by p.ProductID


--QUESTION 2
select sc.CustomerID, COALESCE(pp.LastName, 'unkown') as [LastName], COALESCE(pp.FirstName, 'unkown') as [FirstName]
from Sales.SalesOrderHeader soh
right join Sales.Customer sc on sc.CustomerID = soh.CustomerID
left join Person.Person pp on sc.CustomerID = pp.BusinessEntityID
where soh.CustomerID is null
order by sc.CustomerID

--QUESTION 3
SELECT TOP 10 sc.CustomerID, COALESCE(pp.FirstName, 'unknown') as [FirstName], COALESCE(pp.LastName, 'unknown') as [LastName] , COUNT(soh.CustomerID) as OrderCount
FROM Sales.Customer sc
LEFT JOIN Sales.SalesOrderHeader soh ON sc.CustomerID = soh.CustomerID
LEFT JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID
WHERE soh.CustomerID IS NOT NULL
GROUP BY sc.CustomerID, pp.FirstName, pp.LastName
ORDER BY OrderCount DESC

--QUESTION 4
SELECT pp.FirstName, pp.LastName, he.HireDate, he.JobTitle, (select count(*) from HumanResources.Employee sq_he where sq_he.JobTitle = he.JobTitle) as JobCount 
FROM HumanResources.Employee he
join Person.Person pp on pp.BusinessEntityID = he.BusinessEntityID

--QUESTION 5 
WITH CustomerInfo AS (
	SELECT 	
		ROW_NUMBER() OVER (PARTITION BY j_sc.CustomerID ORDER BY soh.OrderDate DESC) rowNum,
		soh.SalesOrderID,
		j_sc.CustomerID, 
		j_pp.LastName, 
		j_pp.FirstName,
		soh.OrderDate as LastOrder
	from 
		Sales.SalesOrderHeader soh
	left outer join
		Sales.Customer j_sc on j_sc.CustomerID = soh.CustomerID
	left outer join 
		Person.Person j_pp on j_pp.BusinessEntityID = j_sc.PersonID
)

SELECT 
	ci.SalesOrderID,
	ci.CustomerID,
	ci.LastName,
	ci.FirstName,
	ci.LastOrder,
	ci2.LastOrder as PreviousOrder 
from 
	CustomerInfo ci
left join
	CustomerInfo ci2 on ci2.CustomerID = ci.CustomerID and ci.rowNum = ci2.rowNum - 1
where ci.rowNum = 1
order by ci.LastName


--QUESTION 6
with Total as (
	select distinct
		soh.CustomerID,
		sod.SalesOrderID,
		SUM(sod.UnitPrice*(1-sod.UnitPriceDiscount)*sod.OrderQty) as Total,
		DATEPART(yyyy, soh.OrderDate) as Year
	from 
		Sales.SalesOrderDetail sod
	inner join
		Sales.SalesOrderHeader soh on soh.SalesOrderID = sod.SalesOrderID
	GROUP BY 
		soh.CustomerID,
		sod.SalesOrderID,
		DATEPART(yyyy, soh.OrderDate)
)
select 
	sqT.Year, 
	sqT.SalesOrderID, 
	(
		select pp.LastName
		from
			Sales.Customer sc
		join
			Person.Person pp on pp.BusinessEntityID = sc.PersonID
		where sqT.CustomerID = sc.CustomerID
	) as LastName,
	(
		select pp.FirstName
		from
			Sales.Customer sc
		join
			Person.Person pp on pp.BusinessEntityID = sc.PersonID
		where sqT.CustomerID = sc.CustomerID
	) as First,
	sqT.Total
from (
	SELECT 
		t.Year,
		t.SalesOrderID,
		t.Total,
		DENSE_RANK() OVER(Partition by t.year order by t.total DESC) as Rank,
		t.CustomerID
	FROM 
		Total as t
) as sqT

where sqT.Rank = 1


--QUESTION 7
select Month, [2011], [2012], [2013], [2014]
from (
	select datepart(yyyy, OrderDate) as Year , datepart(mm, OrderDate) as month, SalesOrderID
	from Sales.SalesOrderHeader
	) as soh
pivot (
	COUNT(SalesOrderID)
	for Year IN ([2011], [2012], [2013], [2014])
) as pvt
order by month
go

--QUESTION 8
WITH sumDue AS (
    SELECT 
        DATEPART(yyyy, soh.OrderDate) AS [year], 
        DATEPART(mm, soh.OrderDate) AS [month], 
        CAST(SUM(sod.LineTotal) AS decimal(38,2)) AS Total
    FROM sales.SalesOrderHeader soh
    JOIN 
		Sales.SalesOrderDetail sod ON 
		sod.SalesOrderID = soh.SalesOrderID
    GROUP BY 
		DATEPART(yyyy, soh.OrderDate), 
		DATEPART(mm, soh.OrderDate)
)
SELECT 
    s.[year] as year, 
    cast(s.[month] as varchar(30)) as month, 
    SUM(s.Total) as Sum_Price,
    (
        SELECT SUM(s2.Total)
        FROM sumDue s2
        WHERE 
			s2.[year] = s.[year]
            AND 
			s2.[month] <= s.[month]
    ) AS money
FROM sumDue s
group by s.[year], s.[month]

union

SELECT 
    DATEPART(yyyy, soh.OrderDate) AS [year], 
	'grand_total',
	null,
	(
	select 
		sum(sod.LineTotal) total
	from sales.SalesOrderHeader soh2
	join Sales.SalesOrderDetail sod on sod.SalesOrderID = soh2.SalesOrderID
	where datepart(yyyy, soh2.OrderDate) = DATEPART(yyyy, soh.OrderDate)
	group by datepart(yyyy, soh2.OrderDate)
	) as sq
FROM sales.SalesOrderHeader soh
JOIN 
	Sales.SalesOrderDetail sod ON 
	sod.SalesOrderID = soh.SalesOrderID
GROUP BY 
	DATEPART(yyyy, soh.OrderDate)


order by year, money
go

-- QUESITON 9
-- Answer in enabley is probably different fro some reason, after I checked it has a close previous hired employee than what is showed in enably. for examle Chris Norred and Jay Adams are the closest
-- employees by hire date and nnot like in the enabley
go
CREATE OR ALTER FUNCTION dbo.getHirePrevDate (@id int)
RETURNS datetime
BEGIN
	DECLARE @prevDate datetime
	SELECT top 1
		@prevDate = prevHe.HireDate
	FROM 
		HumanResources.Employee prevHe
	join 
		Person.Person pp2 on pp2.BusinessEntityID = prevHe.BusinessEntityID

	WHERE 
		prevHe.HireDate < (
		SELECT he3.HireDate
		FROM 
			HumanResources.Employee he3
		join 
			Person.Person pp3 on pp3.BusinessEntityID = he3.BusinessEntityID
		WHERE he3.BusinessEntityID = @id
		)
	order by prevHe.HireDate desc
		
	return @prevDate
END
go

go
CREATE OR ALTER FUNCTION dbo.getPrevHireName (@id int)
RETURNS nvarchar(max)
BEGIN
	DECLARE @prevName nvarchar(max)
	SELECT top 1
		@prevName = concat(pp2.FirstName, ' ', pp2.LastName)
	FROM 
		HumanResources.Employee prevHe
	join 
		Person.Person pp2 on pp2.BusinessEntityID = prevHe.BusinessEntityID

	WHERE 
		prevHe.HireDate < (
		SELECT he3.HireDate
		FROM 
			HumanResources.Employee he3
		join 
			Person.Person pp3 on pp3.BusinessEntityID = he3.BusinessEntityID
		WHERE he3.BusinessEntityID = @id
		)
	order by prevHe.HireDate desc
		
	return @prevName
END
go



select 
	hd.Name DepartmentName, 
	he.BusinessEntityID as EmployeeID, 
	concat(pp.FirstName, ' ', pp.LastName) EmployeeFullName, 
	he.HireDate HireDate,
	DATEDIFF(mm, he.HireDate, GETDATE()) DateDiff,
	dbo.getPrevHireName(he.BusinessEntityID) as PreviousEmpName,
	dbo.getHirePrevDate(he.BusinessEntityID) as PreviousHireDate,
	DATEDIFF(dd, dbo.getHirePrevDate(he.BusinessEntityID), he.HireDate) as DayDiff

from 
	HumanResources.Employee he
join 
	Person.Person pp on pp.BusinessEntityID = he.BusinessEntityID
join 
	HumanResources.EmployeeDepartmentHistory edh on edh.BusinessEntityID = he.BusinessEntityID
join 
	HumanResources.Department hd on hd.DepartmentID = edh.DepartmentID

order by hd.Name, he.BusinessEntityID desc
go

-- QUESTION 10
with sameHire as
(
	select 
		he.HireDate, 
		heh.DepartmentID, 
		concat(he.BusinessEntityID,' ',pp.LastName,' ',pp.FirstName) as EmployeeInfo
	from 
		Person.Person pp
	join 
		HumanResources.Employee he on pp.BusinessEntityID = he.BusinessEntityID
	join 
		HumanResources.EmployeeDepartmentHistory heh on heh.BusinessEntityID = pp.BusinessEntityID
	join 
		HumanResources.Department hd on hd.DepartmentID = heh.DepartmentID
	where 
		heh.enddate is null
)
	select 
		sh.HireDate, 
		sh.DepartmentID, 
		STRING_AGG(sh.EmployeeInfo,', ') as EmployeesInfo
	from 
		sameHire sh
	group by 
		sh.hiredate, 
		sh.departmentid
	order by sh.HireDate
