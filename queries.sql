-- ============================================================
-- Product Management Case Study: Advanced Player Behavior Queries
-- Dataset: synthetic_player_events.csv
-- ============================================================

-- 1. ACTIVATION & ONBOARDING FUNNEL
WITH onboarding AS (
    SELECT 
        event_name,
        COUNT(DISTINCT player_id) AS unique_players
    FROM synthetic_player_events
    WHERE event_name IN ('install', 'tutorial_start', 'tutorial_complete')
    GROUP BY event_name
)
SELECT 
    event_name,
    unique_players,
    ROUND(100.0 * unique_players / FIRST_VALUE(unique_players) OVER (ORDER BY unique_players DESC), 2) AS conversion_rate_pct
FROM onboarding;


-- 2. DAY 1, DAY 7, AND DAY 30 USER RETENTION
WITH player_first_day AS (
    SELECT 
        player_id, 
        MIN(DATE(event_timestamp)) AS install_date
    FROM synthetic_player_events
    GROUP BY player_id
),
player_activity AS (
    SELECT DISTINCT 
        e.player_id,
        DATEDIFF(DATE(e.event_timestamp), f.install_date) AS day_number
    FROM synthetic_player_events e
    JOIN player_first_day f ON e.player_id = f.player_id
)
SELECT 
    COUNT(DISTINCT player_id) AS total_installs,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN day_number = 1 THEN player_id END) / COUNT(DISTINCT player_id), 2) AS d1_retention_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN day_number = 7 THEN player_id END) / COUNT(DISTINCT player_id), 2) AS d7_retention_pct,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN day_number = 30 THEN player_id END) / COUNT(DISTINCT player_id), 2) AS d30_retention_pct
FROM player_activity;


-- 3. CHANNEL MONETIZATION PERFORMANCE (ARPU & ARPPU)
SELECT 
    acquisition_channel,
    COUNT(DISTINCT player_id) AS total_players,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN player_id END) AS paying_players,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN player_id END) / COUNT(DISTINCT player_id), 2) AS payer_conversion_pct,
    ROUND(SUM(COALESCE(purchase_amount, 0)), 2) AS total_revenue,
    ROUND(SUM(COALESCE(purchase_amount, 0)) / COUNT(DISTINCT player_id), 2) AS arpu,
    ROUND(SUM(COALESCE(purchase_amount, 0)) / NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN player_id END), 0), 2) AS arppu
FROM synthetic_player_events
GROUP BY acquisition_channel
ORDER BY total_revenue DESC;


-- 4. LEVEL FAILURE & FRICTION POINTS (PROGRESSION BOTTLENECKS)
SELECT 
    level,
    COUNT(CASE WHEN event_name = 'level_fail' THEN 1 END) AS total_fails,
    COUNT(CASE WHEN event_name = 'level_complete' THEN 1 END) AS total_completes,
    ROUND(
        100.0 * COUNT(CASE WHEN event_name = 'level_fail' THEN 1 END) / 
        NULLIF(COUNT(CASE WHEN event_name = 'level_fail' THEN 1 END) + COUNT(CASE WHEN event_name = 'level_complete' THEN 1 END), 0), 
        2
    ) AS fail_rate_pct
FROM synthetic_player_events
WHERE level IS NOT NULL
GROUP BY level
HAVING (total_fails + total_completes) > 10
ORDER BY fail_rate_pct DESC
LIMIT 5;


-- 5. FEATURE UNLOCK VS. FEATURE USAGE ENGAGEMENT
SELECT 
    feature_name,
    COUNT(DISTINCT CASE WHEN event_name = 'feature_unlocked' THEN player_id END) AS unlocked_players,
    COUNT(DISTINCT CASE WHEN event_name = 'feature_used' THEN player_id END) AS active_users,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN event_name = 'feature_used' THEN player_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN event_name = 'feature_unlocked' THEN player_id END), 0), 
        2
    ) AS feature_adoption_pct
FROM synthetic_player_events
WHERE feature_name IS NOT NULL
GROUP BY feature_name;
