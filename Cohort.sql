select * from `UCI.online_retail`;


/*DATA CLEANING

# 1. MISSING VALUES

# Count of Customer id with null*/

Select count(*)
from `UCI.online_retail`
where CustomerID is null;

/*# 135080 records dont have customer id*/

SELECT count(CustomerID)
from `UCI.online_retail`;

/* 406829 records have customer id*/

create view UCI.df as
(
  SELECT * 
  from `UCI.online_retail`
  where CustomerID is not null and Quantity>0 and UnitPrice>0
);

/* Data is reduced to 397884 records*/

select * from `UCI.df`;


/*Duplicate Check*/

Select count(*)
from
(
SELECT *, row_number() over(partition by InvoiceNo, StockCode, Quantity order by InvoiceDate ) as dup_flag
from `UCI.df`
) as t1
where dup_flag !=1;

/*5215 duplicate rows found*/

create view UCI.retail_data as
(
Select *
from
(
SELECT *, row_number() over(partition by InvoiceNo, StockCode, Quantity order by InvoiceDate ) as dup_flag
from `UCI.df`
) as t1
where dup_flag =1
);

select * from `UCI.retail_data`;
--392669 records left


--Begin Cohort Analysis
--Unique Identifier (CustomerID)
--Initial Start Date (First Invoice Date)
--Revenue Data


create view UCI.cohort as
(
select CustomerID,
min(InvoiceDate) as first_purchase_date,
extract(year FROM min(InvoiceDate)) as cohort_year,
extract(month from min(InvoiceDate)) as cohort_month
from `UCI.retail_data`
group by CustomerID
);


select * from `UCI.cohort`;



---Creating cohort index

create view UCI.cohort_retention as
(
select *,year_diff*12 + month_diff + 1 as cohort_index
from
(
SELECT t1.*,
invoice_year-cohort_year as year_diff,
invoice_month-cohort_month as month_diff
from
(
SELECT l.*,concat(r.Cohort_year,'-',r.Cohort_month) as Cohort_Date,
extract(year from l.InvoiceDate) as invoice_year,
extract(month from l.InvoiceDate) as invoice_month,
r.cohort_year, r.cohort_month
from `UCI.retail_data` l
left join `UCI.cohort` r
on l.CustomerID=r.CustomerID
)t1
)t2
);


select * from `UCI.cohort_retention`;


---Creating Cohort Table
---Pivot Data to see the cohort table

SELECT *
from
(
select distinct CustomerID,Cohort_Date,cohort_index
from `UCI.cohort_retention`
)tbl
pivot(count(CustomerID) for Cohort_Index in(
  1, 2, 3, 4, 5, 6, 7,8, 9, 10, 11, 12,13)
) as pivot_table