create database "Retail Data Analysis"
use "Retail Data Analysis"

select * from Customer
select * from transactions
select * from prod_cat_info

--DATA PREPARATION AND UNDERSTANDING

--1. What is the total number of rows in each of the 3 tables in the database? 
select 'Customer' as 'Table Name',count(*) as 'No. of Rows' from Customer
union  
select 'Transactions',COUNT(*) from Transactions
union 
select 'Prod_cat_info',COUNT(*) from prod_cat_info

--2. What is the total number of transactions that have a return?

--Total number of transactions that have a return(Profit)
select 
count(transaction_id)'No. Of Transactions' 
from Transactions
where total_amt > 0

--Total number of transactions that have a return(product got back as a return from customer)
select 
count(transaction_id) 
from Transactions
where total_amt < 0

--3. As you would have noticed, the dates provided across the datasets are not in a 
--correct format. As first steps, pls convert the date variables into valid date formats before proceeding ahead.
select 
convert(date,DOB,101) 'Customer Table'
from Customer
select 
convert(date,tran_date,101) 'Transaction Table'
from Transactions

--4. What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns. 

select 
DATEDIFF(yy,MIN(convert(date,tran_date,101)), MAX(convert(date,tran_date,101))) 'Year',
DATEDIFF(mm,MIN(convert(date,tran_date,101)), MAX(convert(date,tran_date,101))) 'Month',
DATEDIFF(DY,MIN(convert(date,tran_date,101)), MAX(convert(date,tran_date,101))) 'Days'
from Transactions

--5. Which product category does the sub-category “DIY” belong to? 
select 
prod_cat
from prod_cat_info
where prod_subcat = 'DIY'

--DATA ANALYSIS

--1. Which channel is most frequently used for transactions? 
select top 1 Store_type,(COUNT(Store_type))'No. of Transactions' 
from Transactions
group by Store_type
order by COUNT(Store_type) desc

--2. What is the count of Male and Female customers in the database? 
select Gender, COUNT(Gender)'Count of Customers'
from Customer
where Gender is not null
group by Gender

--3. From which city do we have the maximum number of customers and how many? 
select top 1 city_code, COUNT(city_code) 'Count of Customers'
from Customer
group by city_code
order by COUNT(city_code) desc

--4. How many sub-categories are there under the Books category?
select prod_cat, COUNT(prod_subcat)
from prod_cat_info
where prod_cat = 'Books'
group by prod_cat

--5. What is the maximum quantity of products ever ordered? 
select top 1
p.prod_cat 'Product Category',p.prod_subcat'Product Sub-Category',
COUNT(t.prod_cat_code)'No. Of Orders'
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
group by p.prod_cat,p.prod_subcat
order by COUNT(t.prod_cat_code) desc

--6. What is the net total revenue generated in categories Electronics and Books? 
select p.prod_cat 'Product Category',SUM(t.total_amt) 'Total Revenue'
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
where p.prod_cat in ('Electronics','Books')
group by p.prod_cat
order by SUM(t.total_amt)

--7. How many customers have >10 transactions with us, excluding returns? 

--All the customers with > 10 transactions  
select cust_id 'Customer ID', COUNT(transaction_id)'No. Of Transactions'
from Transactions
group by cust_id
having COUNT(transaction_id) > 10
order by COUNT(transaction_id) desc

-- Total no. of Customers = 36
select COUNT(customer_Id) 'No. Of Customers'
from Customer
where customer_Id in 
(select cust_id
from Transactions
group by cust_id
having COUNT(transaction_id) > 10)

/*8. What is the combined revenue earned from the “Electronics” & “Clothing” 
categories, from “Flagship stores”? */

select p.prod_cat, SUM(t.total_amt), t.Store_type
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
where t.Store_type = 'Flagship store' and p.prod_cat in ('Electronics', 'Clothing')
group by p.prod_cat,t.Store_type

--9. What is the total revenue generated from “Male” customers in “Electronics” 
--category? Output should display total revenue by prod sub-cat. 
select c.Gender, p.prod_cat, p.prod_subcat, SUM(t.total_amt)
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code 
join Customer c on c.customer_Id = t.cust_id
where c.Gender = 'M' and p.prod_cat = 'Electronics'
group by p.prod_cat, p.prod_subcat, c.Gender

--10.What is percentage of sales and returns by product sub category; display only top 5 
--sub categories in terms of sales? 

select top 5 p.prod_subcat, SUM(t.total_amt)'Sales return', 
(sum(t.total_amt) * 100)/(select SUM(total_amt) from Transactions) 'Percentage of Sales'
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
group by p.prod_subcat
order by SUM(t.total_amt) desc

--11. For all customers aged between 25 to 35 years find what is the net total revenue 
--generated by these consumers in last 30 days of transactions from max transaction date available in the data?
select 
datediff(YY,convert(date,c.DOB,101), convert(date,GETDATE(),101)) 'Age',
SUM(t.total_amt) 'Total Revenue'
from Transactions t join Customer c
on t.cust_id = c.customer_Id
group by  datediff(YY,convert(date,c.DOB,101), convert(date,GETDATE(),101))
having datediff(YY,convert(date,c.DOB,101), convert(date,GETDATE(),101)) between 25 and 35
order by Age

--12.Which product category has seen the max value of returns in the last 3 months of 
--transactions? 
select p.prod_cat, SUM(t.total_amt)
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
where datepart(mm,t.tran_date) between  datediff(mm,GETDATE(),3) and datepart(mm,GETDATE())
group by p.prod_cat

--13.Which store-type sells the maximum products; by value of sales amount and by 
--quantity sold? 
select top 1 Store_type, count(transaction_id) 'No. of Sales', SUM(total_amt) 'Sales amount'
from Transactions
group by Store_type
order by COUNT(transaction_id) desc, sum(total_amt) desc

--14.What are the categories for which average revenue is above the overall average. 
select  p.prod_cat,AVG(t.total_amt) 
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
group by p.prod_cat
having AVG(t.total_amt) > (select AVG(total_amt) from Transactions)


--15. Find the average and total revenue by each subcategory for the categories which 
--are among top 5 categories in terms of quantity sold.

select p1.prod_cat[Product Category],p1.prod_subcat[Product Subcategory], 
AVG(t1.total_amt) [Average Revenue], SUM (t1.total_amt) [Total Revenue]
from Transactions t1 join prod_cat_info p1 
on t1.prod_cat_code = p1.prod_cat_code and t1.prod_subcat_code = p1.prod_sub_cat_code  
where p1.prod_cat in  
(select top 5 p.prod_cat
from Transactions t join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code 
group by prod_cat
order by COUNT(t.transaction_id) desc)
group by p1.prod_subcat, p1.prod_cat

