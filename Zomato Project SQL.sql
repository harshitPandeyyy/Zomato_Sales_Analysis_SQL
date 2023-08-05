select * from goldusers_signup
select * from product
select * from sales
select * from users

--1. Total amount each person has spent on zomato

select a.userid, sum(b.price) from sales a
inner join product b on a.product_id = b.product_id

group by a.userid

--2. How many days has each customer has visited zomato

select userid, count(distinct created_date) as distinct_days  from sales
group by userid

--3. What was the first product purchased by each customer

select * from
(select *, rank() over(partition by userid order by created_date) as rnk from sales) a where rnk = 1

--4. What is the most purchased item on the menu and how many times was it purchased by the customers?

select product_id , count(product_id) bought_times from sales
group by product_id
order by count(product_id) DESC

--5. At what time and which customer bought the product

select * from sales where product_id =
(select product_id  from sales
group by product_id
order by count(product_id) DESC limit 1)

--6. Which customer has bought it most of the times

select userid, count(product_id) as cnt from sales where product_id =
(select product_id  from sales
group by product_id
order by count(product_id) DESC limit 1)
group by userid

--7. Which item was most popular for each customer

select * from
(select *, rank() over(PARTITION by userid order by cnt desc) rnk from
(select userid, product_id , count(product_id) cnt from sales
group by userid, product_id) a) b where rnk = 1

--8. Which item was purchased by each customer after becomeing premium member?

select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid
and a.created_date >= b.gold_signup_date

--9. Which first item was purchased by each customer after becomeing premium member?

select * from
(select c.*, rank() over(partition by userid order by created_date) rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid
and a.created_date >= b.gold_signup_date) c) d where rnk = 1

--10. Which item was purchased by the customer before becoming the premium member?

SELECT * from
(select c.*, rank() over(partition by userid order by created_date desc) rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid = b.userid and a.created_date <= b.gold_signup_date) c) d where rnk =1

--11. What is the total orders and amount spent for each customer?

select a.userid , count(a.product_id) ,sum(b.price) from sales a full outer join product b 
on a.product_id = b.product_id
group by a.userid 
order by a.userid 

--12. What is the total orders and amount spent for each customer before they became a member?

select userid, count(created_date) order_purchased , sum(price) total_amount_spent from 
(select c.*, d.price from
(select a.userid, a.created_date, a.product_id , b.gold_signup_date from sales a inner join 
goldusers_signup b on a.userid = b.userid and created_date <= gold_signup_date) c inner join product d on 
c.product_id = d.product_id) e
group by userid

--13. If buying each product generates points for example 5rs=2 Zomato Points and each product has different
--    purchasing point for example for p1 5yrs=1 Zomato point, for p2 10rs=5 zomato point and p3 5rs = 1 Zomato point

select f.userid , sum(points_earned) as total_points_earned from 
(select e.*, amt/points as points_earned FROM
(select d.* , case
when product_id = 1 then 5 
when product_id = 2 then 2
when product_id = 3 then 5
END as points from
(select c.userid, c.product_id , sum(price) amt from
(select a.userid, a.product_id, b.price from sales a inner join product b
on a.product_id = b.product_id) c
group by userid, product_id) d) e) f
group by userid


--14. In context of reward earned how much money they have earned. 

-- we can say that point=2.5rs 
select f.userid , sum(points_earned)*2.5 as total_points_earned from 
(select e.*, amt/points as points_earned FROM
(select d.* , case
when product_id = 1 then 5 
when product_id = 2 then 2
when product_id = 3 then 5
END as points from
(select c.userid, c.product_id , sum(price) amt from
(select a.userid, a.product_id, b.price from sales a inner join product b
on a.product_id = b.product_id) c
group by userid, product_id) d) e) f
group by userid


--15. Calculate point collected by each customer and for which product most point have given till now.

select * from 
(select * , rank() over(partition by total_point_earned) rnk from
(select product_id ,sum(total_points) as total_point_earned from 
(select e.*, amt/points as total_points FROM
(select d.* , case
when product_id = 1 then 5 
when product_id = 2 then 2
when product_id = 3 then 5
END as points from
(select c.userid, c.product_id , sum(price) amt from
(select a.userid, a.product_id, b.price from sales a inner join product b
on a.product_id = b.product_id) c
group by userid, product_id) d) e) f group by product_id) f) g where rnk=1;


--16. Rank all the transaction of all customes.

select *, rank() over(PARTITION by userid order by created_date) rnk from sales

--17. Rank all the transaction for each member whenever they are a zomato gold member for every non gold member
--    transaction mark as na

select e.*, case when rnk='0'then 'na' else rnk end as rnkk from
(select c.*, cast((case when gold_signup_date is null then 0 else rank() over(partition by userid order by created_date desc) end) as varchar) as rnk from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a left join goldusers_signup b
on a.userid = b.userid
and a.created_date >= b.gold_signup_date) c) e

