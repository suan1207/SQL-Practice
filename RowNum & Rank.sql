listings(
    id,
    city,
    price,
    room_type,
    host_id,
    created_at
)

--1. 按 price 从高到低给所有房源排名
SELECT id,price,
    ROW_NUMBER () OVER (ORDER BY price DESC) AS rank
FROM listings;


--2. 按 city 分组，对每个城市的房源按 price 排名(用 ROW_NUMBER)
SELECT id,city,price,
    ROW_NUMBER () OVER (
         PARTITION BY city
         ORDER BY price DESC
         )
        AS rank_city 
FROM listings;


--3. 按 city 分组，用 RANK() 对房源价格排名
SELECT id,city, price,
    RANK() OVER(
        PARTITION BY city
        ORDER BY price DESC
         )
        AS rank_city 
FROM listings;


--4. 每个城市最贵的房源(Top 1)每个 city 只保留一条 用 ROW_NUMBER()
SELECT *
FROM (SELECT id,
             city,
             price,
        ROW_NUMBER () OVER (
        PARTITION BY city
        ORDER BY price DESC
        )AS rn
    FROM listings)t  #(建立子查询的临时表)
WHERE rn = 1;


--5. 每个城市 Top 3 房源(不考虑并列)rownumber
SELECT *
FROM (SELECT id,
             city,
             price,
        ROW_NUMBER () OVER(
        PARTITION BY city
        ORDER BY price DESC
        ) AS rank_city
    FROM listings)t
WHERE rank_city <= 3;


--6. 每个城市 Top 3 房源（考虑并列）rank
SELECT *
FROM (SELECT id,
             city,
             price,
        RANK () OVER(
        PARTITION BY city
        ORDER BY price DESC
        ) AS rank_city
    FROM listings)t
WHERE rank_city IN (1, 2, 3);


--7. 每个房东最早发布的一条 listing 用 ROW_NUMBER()
SELECT *
FROM (SELECT id, 
       host_id,
       created_at
       ROW_NUMBER () OVER(
        PARTITION BY host_id
        ORDER BY created_at
       ) AS created_order
       FROM listings)t
WHERE created_order = 1;

--8. 房源去重（每个房东保留最新）
SELECT *
FROM (SELECT id, 
       host_id,
       created_at
       ROW_NUMBER () OVER(
        PARTITION BY host_id
        ORDER BY created_at DESC
       ) AS created_order
       FROM listings)t
WHERE created_order = 1;


--9. 找“价格第二高”的房源（全局）
SELECT *
FROM (SELECT id,
       price,
       ROW_NUMBER () OVER(
       ORDER BY price DESC
       ) AS rn
       FROM listings)t
WHERE rn = 2;
       

--10. 找每个城市价格“第二高”的房源
SELECT *
FROM (SELECT id,
       price,
       ROW_NUMBER () OVER(
       PARTITION BY city
       ORDER BY price DESC
       ) AS rn
       FROM listings)t
WHERE rn = 2;


--11. 找价格高于本城市平均价的房源
SELECT *
FROM (SELECT id,
       city,
       price,
       AVG(price) OVER(
        PARTITION BY city) AS avg_price
    FROM listings)t       
WHERE price > avg_price;

--12. 找每个城市：最贵房源、最便宜房源，输出：| city | max_price | min_price |
SELECT 
    id,
    city,
    price, 
    MAX(price) AS max_price,
    MIN(price) AS min_price
FROM listings
GROUP BY city;

--只要统计值 → GROUP BY
--要具体行 → 窗口函数

--13. 每个城市价格前 10% 的房源
SELECT *
FROM (SELECT 
        id,
        city,
        price,
        PERCENT_RANK OVER(
        PARTITION BY city
        ORDER BY price) AS pr
    FROM listings)t       
WHERE pr <= 0.1;