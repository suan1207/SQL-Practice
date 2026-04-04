--datasets：players(id,name,server)
--          game_sessions(id,player_id,mission_id,score)
--          missions(id,mission_name,difficulty)
--          purchase(id,player_id,amount)


--Q1 找出每条游戏记录对应的玩家名字和关卡名称
SELECT gs.id, p.name, m.mission_name
FROM game_sessions AS gs
LEFT JOIN players AS p
ON gs.player_id = p.id
LEFT JOIN missions AS m
ON gs.mission_id = m.id;
-- 每条记录都应该有对应的 player 和 mission，所以 INNER JOIN 更合适；如果担心数据缺失，可以用 LEFT JOIN 做数据质量检查。


--Q2 找出所有玩家及他们的充值金额（包括没有充值的玩家）
SELECT ps.id, ps.name, SUM(pur.amount) AS total_amount
FROM players AS ps
LEFT JOIN purchases AS pur
ON ps.id = pur.player_id
GROUP BY ps.id, ps.name;

--Q3 找出从未充值的玩家
SELECT ps.id, ps.name
FROM players AS ps
LEFT JOIN purchases AS pur
ON ps.id = pur.player_id
WHERE pur.player_id IS NULL;

-- Q4：计算每个玩家的总充值金额（LTV）
SELECT ps.id, ps.name, SUM(pur.amount) AS LTV
FROM players AS ps
LEFT JOIN purchases AS pur
ON ps.id = pur.player_id
GROUP BY ps.id, ps.name;

--SELECT ps.id, ps.name, COALESCE(SUM(pur.amount), 0) AS LTV
--COALESCE(x,0) -> if x is null, then 0

--Q5 找出每个服务器（server）的总充值金额
SELECT ps.server, SUM(pur.amount) AS total_amount
FROM players AS ps
LEFT JOIN purchases AS pur
ON ps.id = pur.player_id
GROUP BY ps.server;


--Q6 找出充值最多的玩家
SELECT ps.id, ps.name, SUM(pur.amount) AS LTV
FROM players AS ps
LEFT JOIN purchases AS pur
ON ps.id = pur.player_id
GROUP BY ps.id, ps.name
ORDER BY LTV DESC
LIMIT = 1;

--//

SELECT id, name, LTV
FROM (
    SELECT 
        ps.id,
        ps.name,
        COALESCE(SUM(pur.amount), 0) AS LTV,
        ROW_NUMBER() OVER (ORDER BY SUM(pur.amount) DESC) AS rn
    FROM players ps
    LEFT JOIN purchases pur
    ON ps.id = pur.player_id
    GROUP BY ps.id, ps.name
) t
WHERE rn = 1;


--Q7 找出每个关卡的平均得分
SELECT m.id, m.mission_name, AVG(gs.score) AS avg_score
FROM MISSIONS AS m
LEFT JOIN game_sessions AS gs
ON m.id = gs.mission_id 
GROUP BY m.id, m.mission_name


--Q8 找出每个玩家的最高分关卡（窗口函数 or 子查询）
SELECT p.id, p.name, m.mission_name, gs.score
FROM(SELECT p.id, 
       p.name,
       gs.score,
       ROW_NUMBER() OVER (
        PARTITION BY ps.id 
        ORDER BY gs.score DESC) AS rn
    LEFT JOIN game_sessions AS gs
    ON p.id = gs.player_id
    LEFT JOIN missions AS m
    ON gs.mission_id = m.id)t
WHERE rn=1;

--Q9 找出每个服务器中充值金额最高的玩家
SELECT p.id, p.name, p.server, LTV
FROM(
    SELECT p.id,
           p.name,
           COALESCE(SUM(pur.amount), 0) AS LTV,
           ROW_NUMBER () OVER(
            PARTITION BY p.server
            ORDER BY COALESCE(SUM(pur.amount), 0) DESC) AS rn
    FROM players AS p
    LEFT JOIN purchases AS pur
        ON p.id = pur.player_id
    GROUP BY p.id, p.name,p.server)t
WHERE rn=1;

--Q10 找出玩过关卡但没有充值的玩家 反映白嫖用户

SELECT
    p.id,
    p.name,
    COUNT(gs.id) AS total_game_sessions,
    SUM(pur.amount) AS total_purchase
FROM players AS p
LEFT JOIN game_sessions AS gs
    ON p.id = gs.player_id
LEFT JOIN purchases AS pur
    ON p.id = pur.player_id
GROUP BY p.id, p.name
HAVING COUNT(gs.id) > 0
    AND SUM(pur.amount) IS NULL

--改进版 (完全忘记有DISTINCT的存在了啊...)
SELECT DISTINCT p.id, p.name
FROM players AS p
INNER JOIN game_sessions AS gs
    ON p.id = gs.player_id
LEFT JOIN purchases pur
    ON p.id = pur.player_id
WHERE pur.player_id IS NULL;


--Q11 找出每个玩家的平均得分，并筛选出高于全服平均分的玩家
SELECT p.id, p.name, avg_score
FROM(    
    SELECT p.id, p.name, AVG(gs.score) AS avg_score
    FROM players AS p
    LEFT JOIN game_sessions AS gs
    ON p.id = gs.player_id
    GROUP BY p.id, p.name
    ) AS t
WHERE avg_score > (
    SELECT AVG(avg_score)
    FROM t
    );
-- ↑ 子查询中的别名 t 只在当前查询层级有效，不能在嵌套子查询中复用，因此需要使用 CTE 或重复子查询来计算全局平均值。改进版见下。

WITH t AS (
    SELECT 
        p.id, 
        p.name, 
        AVG(gs.score) AS avg_score
    FROM players p
    LEFT JOIN game_sessions gs
        ON p.id = gs.player_id
    GROUP BY p.id, p.name
)
SELECT *
FROM t
WHERE avg_score > (
    SELECT AVG(avg_score)
    FROM t
);


--Q12（留存思维）找出至少完成过 2个不同关卡 的玩家
SELECT p.id, p.name
FROM players AS p
INNER JOIN game_sessions AS gs
ON p.id = gs.player_id
GROUP BY p.id, p.name
HAVING COUNT(DISTINCT gs.mission_id) >= 2


-- Q13 找出完成了所有关卡的玩家（NOT EXISTS / HAVING COUNT）
SELECT p.id, p.name
FROM players AS p
INNER JOIN game_sessions AS gs
    ON p.id = gs.player_id
GROUP BY p.id, p.name
HAVING COUNT(DISTINCT gs.mission_id) = (
    SELECT COUNT(mission_id)
    FROM missions
    );