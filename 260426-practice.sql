- table1：players{player_id, register_date, level}
- table2: battles{battle_id, player_id, stage_id, result('win'/'lose'), battle_time}
- table3: stages{stage_id, chapter, difficulty}

- Q1 统计每个关卡的通关次数
SELECT stage_id, COUNT(*) AS win_count
FROM battles
WHERE result = 'win'
GROUP BY stage_id;

- Q2 计算关卡通关率
SELECT 
    s.stage_id,
    AVG(CASE WHEN b.result = 'win' THEN 1 ELSE 0 END) AS win_rate
FROM stages s
LEFT JOIN battles b 
    ON s.stage_id = b.stage_id
GROUP BY s.stage_id;

- Q3 按玩家等级分层（例如 level < 20 / ≥20），计算每一关不同层的平均通关率
#从最小的表开始join, 理论上GROUP BY要先写但是mysql的话直接写level_group会帮你自动展开
SELECT
  (CASE 
    WHEN p.level < 20 THEN 'low'
    ELSE 'high'
  END) AS level_group,
  s.stage_id,
  AVG(CASE WHEN b.result = 'win' THEN 1 ELSE 0) AS win_rate
FROM battles AS b
INNER JOIN players AS p
ON b.player_id = p.player_id
INNER JOIN stages AS s
ON b.stage_id = s.stage_id
GROUP BY (CASE WHEN p.level < 20 THEN 'low' ELSE 'high' END) AS level_group, s.stage_id；


- Q4 玩家在每个关卡第一次失败后再次挑战并成功的比例

WITH first_lose AS (
    SELECT 
        player_id, 
        stage_id,
        MIN(battle_time) AS first_lose_time
    FROM battles
    WHERE result = 'lose'
    GROUP BY player_id, stage_id
),

retry_success AS (
    SELECT DISTINCT f.player_id, f.stage_id
    FROM first_lose f
    JOIN battles b
        ON f.player_id = b.player_id
        AND f.stage_id = b.stage_id
        AND b.battle_time > f.first_lose_time
        AND b.result = 'win'
)

SELECT f.stage_id,
    COUNT(DISTINCT r.player_id, r.stage_id) * 1.0 /
    COUNT(DISTINCT f.player_id, f.stage_id) AS retry_success_rate
FROM first_lose AS f
LEFT JOIN retry_success AS r
ON f.player_id = r.player_id 
  AND f.stage_id = r.stage_id
GROUP BY f.stage_id;
