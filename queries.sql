-- Product Management Case Study: Player Behavior Queries
-- Dataset: synthetic_player_events.csv
-- ============================================================

-- 1. TUTORIAL FUNNEL ANALYSIS
-- Measures drop-off rate across early onboarding steps
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


-- 2. CHANNEL MONETIZATION PERFORMANCE
-- Compares revenue and payer conversion across acquisition channels
SELECT 
    acquisition_channel,
    COUNT(DISTINCT player_id) AS total_players,
    COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN player_id END) AS paying_players,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN player_id END) / COUNT(DISTINCT player_id), 2) AS payer_conversion_pct,
    ROUND(SUM(COALESCE(purchase_amount, 0)), 2) AS total_revenue,
    ROUND(SUM(COALESCE(purchase_amount, 0)) / COUNT(DISTINCT player_id), 2) AS arpu
FROM synthetic_player_events
GROUP BY acquisition_channel
ORDER BY total_revenue DESC;


-- 3. LEVEL FAILURE & FRICTION POINTS
-- Identifies hard levels where players experience high fail counts
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


-- 4. FEATURE UNLOCK ENGAGEMENT
-- Checks engagement rate with Daily Challenge and Streak mechanics
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
WHERE feature_name IS NOT NULL;
GROUP BY feature_name;
