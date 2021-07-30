use "Mobile Data Analysis"

select * from DIM_CUSTOMER
select * from DIM_DATE
select * from DIM_LOCATION
select * from DIM_MANUFACTURER
select * from DIM_MODEL
select * from FACT_TRANSACTIONS

--1. List all the states in which we have customers who have bought cellphones from 2005 till today. 
select l.State
from FACT_TRANSACTIONS f join DIM_LOCATION l on f.IDLocation = l.IDLocation
where DATEPART(YY,f.Date) > 2005
group by l.State, l.Country
order by l.State

--2. What state in the US is buying more 'Samsung' cell phones? 
select top 1 l.State, count(f.IDCustomer)'Count Of Customers'
from FACT_TRANSACTIONS f join DIM_MODEL mo  on f.IDModel = mo.IDModel 
join DIM_MANUFACTURER m on mo.IDManufacturer = m.IDManufacturer
join DIM_LOCATION l on f.IDLocation = l.IDLocation
where m.Manufacturer_Name = 'Samsung' and l.Country = 'US'
group by l.State
order by count(f.IDCustomer) desc

--3. Show the number of transactions for each model per zip code per state. 
select mo.Model_Name, l.ZipCode, l.State ,COUNT(f.IDCustomer) [No. Of Transactions]
from FACT_TRANSACTIONS f join DIM_MODEL mo on f.IDModel = mo.IDModel 
join DIM_LOCATION l on f.IDLocation = l.IDLocation
group by ZipCode, l.State, mo.Model_Name
order by l.State

--4. Show the cheapest cellphone 
select top 1 m.Manufacturer_Name,mo.IDModel, mo.Unit_price
from FACT_TRANSACTIONS f join DIM_MODEL mo on f.IDModel = mo.IDModel join DIM_MANUFACTURER m on mo.IDManufacturer = m.IDManufacturer
order by mo.Unit_price

--5. Find out the average price for each model in the top5 manufacturers 
--in terms of sales quantity and order by average price. 

select mo1.Model_Name,m1.Manufacturer_Name, AVG(f1.TotalPrice)
from FACT_TRANSACTIONS f1 join DIM_MODEL mo1 on f1.IDModel = mo1.IDModel
join DIM_MANUFACTURER m1 on mo1.IDManufacturer = m1.IDManufacturer 
where m1.Manufacturer_Name in
(select top 5  m.Manufacturer_Name
from FACT_TRANSACTIONS f join DIM_MODEL mo on f.IDModel = mo.IDModel
join DIM_MANUFACTURER m on mo.IDManufacturer = m.IDManufacturer
group by m.Manufacturer_Name
order by SUM(f.Quantity) desc)

group by mo1.Model_Name, m1.Manufacturer_Name
order by AVG(f1.TotalPrice)

--6. List the names of the customers and the average amount spent in 2009, 
--where the average is higher than 500 

select c.Customer_Name, AVG(f.TotalPrice * Quantity)
from FACT_TRANSACTIONS f join DIM_CUSTOMER c on f.IDCustomer = c.IDCustomer
where DATEPART(YY, f.Date) = 2009 
group by c.Customer_Name
having AVG(f.TotalPrice * Quantity) > 500

--7. List if there is any model that was in the top 5 in terms of quantity, 
--simultaneously in 2008, 2009 and 2010 
with grp as
(select datepart(YY,f.Date)[Year],mo.Model_Name[Model Name], SUM(f.Quantity)[Quantity], 
RANK() over (partition by datepart(yy,f.date) order by SUM(f.Quantity) desc ) [Rank] 
from FACT_TRANSACTIONS f join DIM_MODEL mo on f.IDModel = mo.IDModel
join DIM_MANUFACTURER m on mo.IDManufacturer = m.IDManufacturer
where datepart(YY,f.Date) in (2008,2009,2010)
group by datepart(YY,f.Date),mo.Model_Name)

select grp.[Model Name] from grp
where grp.Rank <= 5 
group by grp.[Model Name]
having COUNT(grp.[Model Name]) > 1


--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the 
--manufacturer with the 2nd top sales in the year of 2010. 
with qs as(
select m.Manufacturer_Name[Manufacturer], SUM(f.TotalPrice*f.Quantity)[Sales],DATEPART(yy, f.Date)[Year],
ROW_NUMBER() over (partition by DATEPART(yy, f.Date) order by SUM(f.TotalPrice*f.Quantity) desc )[Row] 
from FACT_TRANSACTIONS f join DIM_MODEL mo on f.IDModel = mo.IDModel
join DIM_MANUFACTURER m on mo.IDManufacturer = m.IDManufacturer
where DATEPART(yy, f.Date) in (2009, 2010)
group by m.Manufacturer_Name, DATEPART(yy, f.Date) )

select * from qs
where qs.Row = 2

--9. Show the manufacturers that sold cellphone in 2010 but didn’t in 2009. 
select m.Manufacturer_Name
from DIM_MANUFACTURER m
where exists (select *
              from FACT_TRANSACTIONS f join DIM_MODEL mo on f.IDModel = mo.IDModel 
			  join DIM_MANUFACTURER on m.IDManufacturer = mo.IDManufacturer                
              where f.Date >= '2010-01-01' and f.Date < '2011-01-01') 
					and
      not exists (select *
              from FACT_TRANSACTIONS f join DIM_MODEL mo on f.IDModel = mo.IDModel
			  join DIM_MANUFACTURER on m.IDManufacturer = mo.IDManufacturer
              where f.Date >= '2009-01-01' and  f.Date < '2010-01-01')

--10. Find top 100 customers and their average spend, average quantity by each 
--year. Also find the percentage of change in their spend.

SELECT 
    T1.Customer_Name, T1.Year, T1.Avg_Price,T1.Avg_Qty,
CASE
        WHEN T2.Year IS NOT NULL
        THEN FORMAT(CONVERT(DECIMAL(8,2),(T1.Avg_Price-T2.Avg_Price))/CONVERT(DECIMAL(8,2),T2.Avg_Price),'p') ELSE NULL 
        END AS 'Percentage Change'
    FROM
        (SELECT t2.Customer_Name, YEAR(t1.DATE)[YEAR], AVG(t1.TotalPrice) [Avg_Price], AVG(t1.Quantity) [Avg_Qty] FROM FACT_TRANSACTIONS AS t1 
        left join DIM_CUSTOMER as t2 ON t1.IDCustomer=t2.IDCustomer
        where t1.IDCustomer in (select top 100 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
        group by t2.Customer_Name, YEAR(t1.Date)
        )T1
    left join
        (SELECT t2.Customer_Name, YEAR(t1.DATE)[YEAR], AVG(t1.TotalPrice) [Avg_Price], AVG(t1.Quantity) [Avg_Qty] FROM FACT_TRANSACTIONS AS t1 
        left join DIM_CUSTOMER as t2 ON t1.IDCustomer=t2.IDCustomer
        where t1.IDCustomer in (select top 100 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by SUM(TotalPrice) desc)
        group by t2.Customer_Name, YEAR(t1.Date)
        )T2
        on T1.Customer_Name=T2.Customer_Name and T2.YEAR=T1.YEAR-1