drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

-- Roll Metrics
--1. How many rolls were ordered?

select count(roll_id) from customer_orders

--2. How many unique customer orders were made?

select count(distinct(customer_id)) from customer_orders

--3. How many successful orders were delivered by each driver?

select driver_id, count(order_id) as Total_orders from driver_order 
where cancellation not in ('Cancellation','Customer Cancellation')
group by driver_id

--4. How many each type of roll was delivered?

select roll_id, count(roll_id) roll_count from customer_orders
where order_id in
(select order_id from (
select *, case when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order)
a where order_cancel_details = 'nc' )
group by roll_id

--5. How many veg and non veg rolls were ordered by each customer?


select  a.*, b.roll_name from
(select customer_id, roll_id, count(roll_id) as count_rolls from customer_orders group by customer_id, roll_id )
a inner join rolls b
on a.roll_id = b.roll_id

--6. What is the maximum number of rolls delivered in a single order?

select * from (
select order_id, count(roll_id) as roll_count, DENSE_RANK() over (order by count(roll_id) desc) as rankings from customer_orders
where order_id in
(select order_id from (
select *, case when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order)
a where order_cancel_details = 'nc' )
group by order_id)b where rankings = 1

--7. For each customer, how many delivered rolls had atleast 1 change and how many had no change?

select count(roll_id) as roll_count, customer_id, change from 
(select order_id, roll_id, customer_id, (case when not_included = 0 and extra_included = 0 then 'no change' else 'change' end) change from 
(select order_id, roll_id, customer_id,(case when not_include_items is null or not_include_items in ('','NaN')  then '0' else '1' end) as not_included,
(case when extra_items_included is null or extra_items_included in ('','NaN')  then '0' else '1' end )extra_included from customer_orders)a )v
where order_id in (select order_id from (
select order_id, driver_id, (case when cancellation is null or cancellation in ('','NaN')  then 'NC' else 'C' end) cancellation_status from driver_order)s
where cancellation_status = 'NC')
group by customer_id,change


--8. How many rolls were delivered that had both exclusions and extras?

select count(roll_id) as roll_count from 
(select order_id, roll_id, customer_id, (case when not_include_items is null or not_include_items in ('','NaN')  then '0' else '1' end) as not_included,
(case when extra_items_included is null or extra_items_included in ('','NaN')  then '0' else '1' end )extra_included from customer_orders)a
where order_id in (select order_id from 
(select order_id, driver_id, (case when cancellation is null or cancellation in ('','NaN')  then 'NC' else 'C' end) cancellation_status from driver_order)s
where cancellation_status = 'NC')
and not_included = 1 and extra_included = 1

--9. What was the total number of rolls ordered every hour of the day?

select count(roll_id)roll_count , hrs from 
(select *, concat( datepart(Hour, order_date),'-', datepart(Hour, order_date)+1 ) hrs from customer_orders) a
group by hrs

--10. What was the total number of orders on every day of the week?

select count(distinct(order_id))roll_count , day_name from 
(select *, datename(weekday, order_date) day_name from customer_orders) a
group by day_name

--11. What was the average time in minutes taken by each driver to reach at Faasos HQ to pick up the order?

select driver_id, avg(datepart(Minute, (pickup_time - order_date))) as average_time from customer_orders a inner join driver_order b 
on a.order_id = b.order_id
where a.order_id in (select order_id from 
(select order_id, driver_id, (case when cancellation is null or cancellation in ('','NaN')  then 'NC' else 'C' end) cancellation_status from driver_order)s
where cancellation_status = 'NC')
group by driver_id

--12. Is there any relationship between the no of rolls and how long does the order takes time to be prepared?

select order_id, count(roll_id) roll_count, sum(prep_time)/ count(roll_id) as prep_time_in_mins from (select a.order_id, a.roll_id, datepart(Minute, (pickup_time - order_date)) as prep_time from customer_orders a inner join driver_order b 
on a.order_id = b.order_id
where pickup_time is not null)a
group by order_id

--13. What is the average distance travelled for each customer?    --Data Cleaning

select a.customer_id, avg(cast(trim(replace(lower(distance), 'km',' ')) as float)) dist from customer_orders a inner join driver_order b
on a.order_id = b.order_id
where distance is not null
group by customer_id

--14. What is the difference between the longest and the shortest delivery times for all orders?

select max(cast(case when duration like '%min%' then left(duration,CHARINDEX('m', duration)-1) else duration end as int))-
min(cast(case when duration like '%min%' then left(duration,CHARINDEX('m', duration)-1) else duration end as int))as 'diff_in_mins'
from driver_order
where duration is not null


--15. What was the average speed for each driver for each delivery?

--s=d/t

select order_id, dist/duration as avg_speed from (
select order_id, driver_id, cast(case when duration like '%min%' then left(duration,CHARINDEX('m', duration)-1) else duration end as int) duration,
cast(trim(replace(lower(distance), 'km',' ')) as decimal(4,2)) dist from driver_order 
where duration is not null)a
 
--16. What is the successful delivery percentage for each driver?

select driver_id, (succ*1.0/total_orders)*100 as succ_percentage from(
select driver_id, sum(success) succ ,count(driver_id) as total_orders from
(
select driver_id, ((case when cancellation in ('Nan','') or cancellation is null then 1 else 0 end)) as success from driver_order
)a
group by driver_id)t



