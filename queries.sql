-- ============================================================
-- Understanding Player Behavior
-- Product Analytics SQL Case Study
-- Dataset: synthetic_player_events.csv
-- ============================================================
--
-- Analytical flow:
--
-- Observe
--   ↓
-- Analyze
--   ↓
-- Interpret
--   ↓
-- Hypothesize
--   ↓
-- Experiment
--   ↓
-- Measure
--
-- IMPORTANT:
-- This project uses fully synthetic data.
-- Results are not predetermined.
-- These queries are designed to discover behavioral patterns.
-- ============================================================


-- ============================================================
-- 0. LOAD DATA
-- ============================================================
-- DuckDB can read the CSV directly.
-- If the table already exists in your SQL environment,
-- this section can be skipped.
-- ============================================================

CREATE OR REPLACE VIEW synthetic_player_events AS
SELECT *
FROM read_csv_auto('synthetic_player_events.csv');


-- ============================================================
-- 1. BASIC DATA CHECK
-- ============================================================

SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT player_id) AS total_players,
    COUNT(DISTINCT session_id) AS total_sessions,
    MIN("timestamp") AS first_event,
    MAX("timestamp") AS last_event
FROM synthetic_player_events;


-- ============================================================
-- 2. EVENT DISTRIBUTION
-- ============================================================
-- Helps us understand the structure of the event log.
-- ============================================================

SELECT
    event_name,
    COUNT(*) AS event_count,
    COUNT(DISTINCT player_id) AS unique_players
FROM synthetic_player_events
GROUP BY event_name
ORDER BY event_count DESC;


-- ============================================================
-- 3. ACQUISITION CHANNEL DISTRIBUTION
-- ============================================================

SELECT
    acquisition_channel,
    COUNT(DISTINCT player_id) AS players,
    ROUND(
        100.0 * COUNT(DISTINCT player_id)
        / SUM(COUNT(DISTINCT player_id)) OVER (),
        2
    ) AS player_share_pct
FROM synthetic_player_events
GROUP BY acquisition_channel
ORDER BY players DESC;


-- ============================================================
-- 4. ACTIVATION & ONBOARDING FUNNEL
-- ============================================================
--
-- Product question:
-- How many players move from installation
-- to tutorial completion?
-- ============================================================

WITH onboarding AS (

    SELECT
        COUNT(DISTINCT CASE
            WHEN event_name = 'install'
            THEN player_id
        END) AS installed_players,

        COUNT(DISTINCT CASE
            WHEN event_name = 'tutorial_start'
            THEN player_id
        END) AS tutorial_started_players,

        COUNT(DISTINCT CASE
            WHEN event_name = 'tutorial_complete'
            THEN player_id
        END) AS tutorial_completed_players

    FROM synthetic_player_events
)

SELECT
    installed_players,
    tutorial_started_players,
    tutorial_completed_players,

    ROUND(
        100.0 * tutorial_started_players
        / NULLIF(installed_players, 0),
        2
    ) AS tutorial_start_rate_pct,

    ROUND(
        100.0 * tutorial_completed_players
        / NULLIF(installed_players, 0),
        2
    ) AS tutorial_completion_rate_pct,

    ROUND(
        100.0 * tutorial_completed_players
        / NULLIF(tutorial_started_players, 0),
        2
    ) AS tutorial_completion_from_start_pct

FROM onboarding;


-- ============================================================
-- 5. ENGAGEMENT BY PLAYER
-- ============================================================
--
-- Creates player-level behavioral metrics.
-- These metrics will later help us investigate
-- differences in engagement and retention.
-- ============================================================

WITH player_metrics AS (

    SELECT
        player_id,

        COUNT(DISTINCT session_id) AS sessions,

        COUNT(DISTINCT DATE("timestamp"))
            AS active_days,

        COUNT(
            CASE
                WHEN event_name = 'level_start'
                THEN 1
            END
        ) AS level_attempts,

        COUNT(
            CASE
                WHEN event_name = 'level_complete'
                THEN 1
            END
        ) AS levels_completed,

        COUNT(
            CASE
                WHEN event_name = 'level_fail'
                THEN 1
            END
        ) AS level_failures,

        COUNT(
            CASE
                WHEN event_name = 'feature_used'
                THEN 1
            END
        ) AS feature_uses,

        COUNT(
            CASE
                WHEN event_name = 'purchase'
                THEN 1
            END
        ) AS purchase_events,

        COALESCE(
            SUM(
                CASE
                    WHEN event_name = 'purchase'
                    THEN purchase_amount
                    ELSE 0
                END
            ),
            0
        ) AS total_spend

    FROM synthetic_player_events

    GROUP BY player_id
)

SELECT
    *
FROM player_metrics
ORDER BY active_days DESC, sessions DESC;


-- ============================================================
-- 6. ENGAGEMENT SUMMARY
-- ============================================================

WITH player_metrics AS (

    SELECT
        player_id,

        COUNT(DISTINCT session_id) AS sessions,

        COUNT(DISTINCT DATE("timestamp"))
            AS active_days,

        COUNT(
            CASE
                WHEN event_name = 'level_complete'
                THEN 1
            END
        ) AS levels_completed,

        COUNT(
            CASE
                WHEN event_name = 'feature_used'
                THEN 1
            END
        ) AS feature_uses

    FROM synthetic_player_events

    GROUP BY player_id
)

SELECT
    ROUND(AVG(sessions), 2) AS avg_sessions_per_player,
    ROUND(AVG(active_days), 2) AS avg_active_days_per_player,
    ROUND(AVG(levels_completed), 2) AS avg_levels_completed,
    ROUND(AVG(feature_uses), 2) AS avg_feature_uses
FROM player_metrics;


-- ============================================================
-- 7. RETENTION
-- ============================================================
--
-- The generator covers 30 observation days:
-- Day 0 → Day 29
--
-- Therefore:
-- D1  = first day after installation
-- D7  = seventh day after installation
-- D29 = final observed day in the 30-day window
--
-- We do NOT label Day 29 as D30 because the dataset
-- does not contain a full 30-day-after-install observation.
-- ============================================================

WITH first_activity AS (

    SELECT
        player_id,
        MIN(DATE("timestamp")) AS install_date
    FROM synthetic_player_events
    GROUP BY player_id
),

player_activity AS (

    SELECT DISTINCT
        e.player_id,

        DATE_DIFF(
            'day',
            f.install_date,
            DATE(e."timestamp")
        ) AS day_number

    FROM synthetic_player_events e

    JOIN first_activity f
        ON e.player_id = f.player_id
)

SELECT

    COUNT(DISTINCT player_id)
        AS total_players,

    COUNT(DISTINCT CASE
        WHEN day_number = 1
        THEN player_id
    END) AS d1_players,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN day_number = 1
            THEN player_id
        END)
        / COUNT(DISTINCT player_id),
        2
    ) AS d1_retention_pct,

    COUNT(DISTINCT CASE
        WHEN day_number = 7
        THEN player_id
    END) AS d7_players,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN day_number = 7
            THEN player_id
        END)
        / COUNT(DISTINCT player_id),
        2
    ) AS d7_retention_pct,

    COUNT(DISTINCT CASE
        WHEN day_number = 29
        THEN player_id
    END) AS day29_players,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN day_number = 29
            THEN player_id
        END)
        / COUNT(DISTINCT player_id),
        2
    ) AS day29_retention_pct

FROM player_activity;


-- ============================================================
-- 8. RETENTION BY TUTORIAL COMPLETION
-- ============================================================
--
-- Product question:
-- Is tutorial completion associated with
-- subsequent return behavior?
--
-- IMPORTANT:
-- This is an association, not proof of causation.
-- ============================================================

WITH player_status AS (

    SELECT
        player_id,

        MAX(
            CASE
                WHEN event_name = 'tutorial_complete'
                THEN 1
                ELSE 0
            END
        ) AS tutorial_completed

    FROM synthetic_player_events

    GROUP BY player_id
),

first_activity AS (

    SELECT
        player_id,
        MIN(DATE("timestamp")) AS install_date

    FROM synthetic_player_events

    GROUP BY player_id
),

activity AS (

    SELECT DISTINCT
        e.player_id,

        DATE_DIFF(
            'day',
            f.install_date,
            DATE(e."timestamp")
        ) AS day_number

    FROM synthetic_player_events e

    JOIN first_activity f
        ON e.player_id = f.player_id
)

SELECT

    s.tutorial_completed,

    COUNT(DISTINCT s.player_id)
        AS players,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN a.day_number = 7
            THEN a.player_id
        END)
        / COUNT(DISTINCT s.player_id),
        2
    ) AS d7_retention_pct

FROM player_status s

LEFT JOIN activity a
    ON s.player_id = a.player_id

GROUP BY s.tutorial_completed

ORDER BY s.tutorial_completed DESC;


-- ============================================================
-- 9. PROGRESSION & FRICTION
-- ============================================================
--
-- Product question:
-- Are there progression points where failure
-- becomes more common?
--
-- We do NOT assume any specific level is problematic.
-- The data determines the pattern.
-- ============================================================

SELECT

    level,

    COUNT(
        CASE
            WHEN event_name = 'level_start'
            THEN 1
        END
    ) AS level_starts,

    COUNT(
        CASE
            WHEN event_name = 'level_complete'
            THEN 1
        END
    ) AS completions,

    COUNT(
        CASE
            WHEN event_name = 'level_fail'
            THEN 1
        END
    ) AS failures,

    ROUND(
        100.0 *
        COUNT(
            CASE
                WHEN event_name = 'level_fail'
                THEN 1
            END
        )
        /
        NULLIF(
            COUNT(
                CASE
                    WHEN event_name IN (
                        'level_fail',
                        'level_complete'
                    )
                    THEN 1
                END
            ),
            0
        ),
        2
    ) AS fail_rate_pct

FROM synthetic_player_events

WHERE level > 0

GROUP BY level

HAVING COUNT(
    CASE
        WHEN event_name IN (
            'level_fail',
            'level_complete'
        )
        THEN 1
    END
) >= 20

ORDER BY fail_rate_pct DESC;


-- ============================================================
-- 10. RETRY BEHAVIOR AFTER FAILURE
-- ============================================================
--
-- Product question:
-- When players fail, do they keep trying?
-- ============================================================

WITH failed_levels AS (

    SELECT
        player_id,
        level,
        COUNT(*) AS failures

    FROM synthetic_player_events

    WHERE event_name = 'level_fail'

    GROUP BY
        player_id,
        level
)

SELECT

    failures,

    COUNT(DISTINCT player_id) AS players,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN failures >= 2
            THEN player_id
        END)
        / COUNT(DISTINCT player_id),
        2
    ) AS players_with_multiple_failures_pct

FROM failed_levels

GROUP BY failures

ORDER BY failures;


-- ============================================================
-- 11. FEATURE UNLOCK VS FEATURE USAGE
-- ============================================================
--
-- Product question:
-- Does discovering a feature translate into usage?
-- ============================================================

WITH feature_metrics AS (

    SELECT

        feature_name,

        COUNT(DISTINCT CASE
            WHEN event_name = 'feature_unlocked'
            THEN player_id
        END) AS unlocked_players,

        COUNT(DISTINCT CASE
            WHEN event_name = 'feature_used'
            THEN player_id
        END) AS active_users

    FROM synthetic_player_events

    WHERE event_name IN (
        'feature_unlocked',
        'feature_used'
    )

    AND feature_name IS NOT NULL

    GROUP BY feature_name
)

SELECT

    feature_name,

    unlocked_players,

    active_users,

    ROUND(
        100.0 * active_users
        / NULLIF(unlocked_players, 0),
        2
    ) AS feature_adoption_pct

FROM feature_metrics

ORDER BY feature_adoption_pct DESC;


-- ============================================================
-- 12. FEATURE USAGE & RETENTION
-- ============================================================
--
-- Product question:
-- Is feature usage associated with stronger return behavior?
--
-- Again: association ≠ causation.
-- ============================================================

WITH feature_users AS (

    SELECT DISTINCT
        player_id

    FROM synthetic_player_events

    WHERE event_name = 'feature_used'
),

first_activity AS (

    SELECT
        player_id,
        MIN(DATE("timestamp")) AS install_date

    FROM synthetic_player_events

    GROUP BY player_id
),

d7_activity AS (

    SELECT DISTINCT
        e.player_id

    FROM synthetic_player_events e

    JOIN first_activity f
        ON e.player_id = f.player_id

    WHERE DATE_DIFF(
        'day',
        f.install_date,
        DATE(e."timestamp")
    ) = 7
)

SELECT

    CASE
        WHEN f.player_id IS NOT NULL
        THEN 'Feature User'
        ELSE 'Non Feature User'
    END AS feature_group,

    COUNT(DISTINCT p.player_id) AS players,

    COUNT(DISTINCT d.player_id) AS d7_returning_players,

    ROUND(
        100.0 *
        COUNT(DISTINCT d.player_id)
        / COUNT(DISTINCT p.player_id),
        2
    ) AS d7_retention_pct

FROM (
    SELECT DISTINCT player_id
    FROM synthetic_player_events
) p

LEFT JOIN feature_users f
    ON p.player_id = f.player_id

LEFT JOIN d7_activity d
    ON p.player_id = d.player_id

GROUP BY feature_group;


-- ============================================================
-- 13. MONETIZATION OVERVIEW
-- ============================================================

SELECT

    COUNT(DISTINCT player_id)
        AS total_players,

    COUNT(DISTINCT CASE
        WHEN event_name = 'purchase'
        THEN player_id
    END) AS paying_players,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN event_name = 'purchase'
            THEN player_id
        END)
        / COUNT(DISTINCT player_id),
        2
    ) AS payer_conversion_pct,

    ROUND(
        SUM(
            CASE
                WHEN event_name = 'purchase'
                THEN purchase_amount
                ELSE 0
            END
        ),
        2
    ) AS total_revenue,

    ROUND(
        SUM(
            CASE
                WHEN event_name = 'purchase'
                THEN purchase_amount
                ELSE 0
            END
        )
        / COUNT(DISTINCT player_id),
        2
    ) AS arpu,

    ROUND(
        SUM(
            CASE
                WHEN event_name = 'purchase'
                THEN purchase_amount
                ELSE 0
            END
        )
        /
        NULLIF(
            COUNT(DISTINCT CASE
                WHEN event_name = 'purchase'
                THEN player_id
            END),
            0
        ),
        2
    ) AS arppu

FROM synthetic_player_events;


-- ============================================================
-- 14. MONETIZATION CONTEXT
-- ============================================================
--
-- Product question:
-- In what contexts do purchases occur?
-- ============================================================

SELECT

    feature_name AS purchase_context,

    COUNT(*) AS purchase_events,

    COUNT(DISTINCT player_id)
        AS unique_purchasers,

    ROUND(
        SUM(purchase_amount),
        2
    ) AS revenue,

    ROUND(
        AVG(purchase_amount),
        2
    ) AS average_purchase_value

FROM synthetic_player_events

WHERE event_name = 'purchase'

GROUP BY feature_name

ORDER BY revenue DESC;


-- ============================================================
-- 15. MONETIZATION & ENGAGEMENT
-- ============================================================
--
-- Product question:
-- Do paying players also show stronger engagement?
-- ============================================================

WITH player_metrics AS (

    SELECT

        player_id,

        COUNT(DISTINCT session_id)
            AS sessions,

        COUNT(DISTINCT DATE("timestamp"))
            AS active_days,

        COUNT(
            CASE
                WHEN event_name = 'level_complete'
                THEN 1
            END
        ) AS levels_completed,

        COUNT(
            CASE
                WHEN event_name = 'purchase'
                THEN 1
            END
        ) AS purchases,

        COALESCE(
            SUM(
                CASE
                    WHEN event_name = 'purchase'
                    THEN purchase_amount
                    ELSE 0
                END
            ),
            0
        ) AS revenue

    FROM synthetic_player_events

    GROUP BY player_id
)

SELECT

    CASE
        WHEN purchases > 0
        THEN 'Paying Player'
        ELSE 'Non-Paying Player'
    END AS player_group,

    COUNT(*) AS players,

    ROUND(
        AVG(sessions),
        2
    ) AS avg_sessions,

    ROUND(
        AVG(active_days),
        2
    ) AS avg_active_days,

    ROUND(
        AVG(levels_completed),
        2
    ) AS avg_levels_completed,

    ROUND(
        AVG(revenue),
        2
    ) AS avg_revenue

FROM player_metrics

GROUP BY player_group;


-- ============================================================
-- 16. MONETIZATION BY ACQUISITION CHANNEL
-- ============================================================

SELECT

    acquisition_channel,

    COUNT(DISTINCT player_id)
        AS players,

    COUNT(DISTINCT CASE
        WHEN event_name = 'purchase'
        THEN player_id
    END) AS paying_players,

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN event_name = 'purchase'
            THEN player_id
        END)
        / COUNT(DISTINCT player_id),
        2
    ) AS payer_conversion_pct,

    ROUND(
        SUM(
            CASE
                WHEN event_name = 'purchase'
                THEN purchase_amount
                ELSE 0
            END
        ),
        2
    ) AS revenue,

    ROUND(
        SUM(
            CASE
                WHEN event_name = 'purchase'
                THEN purchase_amount
                ELSE 0
            END
        )
        / COUNT(DISTINCT player_id),
        2
    ) AS arpu

FROM synthetic_player_events

GROUP BY acquisition_channel

ORDER BY arpu DESC;


-- ============================================================
-- 17. PLAYER PROGRESSION SUMMARY
-- ============================================================
--
-- Helps identify how far players progress through the game.
-- ============================================================

SELECT

    MAX(level) AS maximum_observed_level,

    ROUND(
        AVG(level),
        2
    ) AS average_event_level,

    COUNT(DISTINCT CASE
        WHEN level >= 3
        THEN player_id
    END) AS players_reaching_level_3,

    COUNT(DISTINCT CASE
        WHEN level >= 5
        THEN player_id
    END) AS players_reaching_level_5,

    COUNT(DISTINCT CASE
        WHEN level >= 10
        THEN player_id
    END) AS players_reaching_level_10

FROM synthetic_player_events

WHERE level > 0;


-- ============================================================
-- 18. PLAYER-LEVEL ANALYTICAL TABLE
-- ============================================================
--
-- This creates a reusable player-level dataset for later
-- Python analysis and visualization.
-- ============================================================

CREATE OR REPLACE VIEW player_behavior_summary AS

WITH first_activity AS (

    SELECT

        player_id,

        MIN(DATE("timestamp"))
            AS install_date

    FROM synthetic_player_events

    GROUP BY player_id
),

player_metrics AS (

    SELECT

        e.player_id,

        COUNT(DISTINCT e.session_id)
            AS sessions,

        COUNT(DISTINCT DATE(e."timestamp"))
            AS active_days,

        COUNT(
            CASE
                WHEN e.event_name = 'level_complete'
                THEN 1
            END
        ) AS levels_completed,

        COUNT(
            CASE
                WHEN e.event_name = 'level_fail'
                THEN 1
            END
        ) AS level_failures,

        COUNT(
            CASE
                WHEN e.event_name = 'feature_used'
                THEN 1
            END
        ) AS feature_uses,

        COUNT(
            CASE
                WHEN e.event_name = 'purchase'
                THEN 1
            END
        ) AS purchase_events,

        COALESCE(
            SUM(
                CASE
                    WHEN e.event_name = 'purchase'
                    THEN e.purchase_amount
                    ELSE 0
                END
            ),
            0
        ) AS total_revenue,

        MAX(e.level)
            AS max_level

    FROM synthetic_player_events e

    GROUP BY e.player_id
)

SELECT

    p.player_id,

    p.sessions,

    p.active_days,

    p.levels_completed,

    p.level_failures,

    p.feature_uses,

    p.purchase_events,

    p.total_revenue,

    p.max_level,

    CASE
        WHEN p.purchase_events > 0
        THEN 1
        ELSE 0
    END AS is_payer

FROM player_metrics p;


-- ============================================================
-- END
-- ============================================================
--
-- The next step is NOT to invent conclusions.
--
-- We will run these queries and examine the actual results.
--
-- Then:
--
-- Observation
--     ↓
-- Behavioral Pattern
--     ↓
-- Product Interpretation
--     ↓
-- Hypothesis
--     ↓
-- Experiment
--     ↓
-- Success / Guardrail Metrics
--
-- ============================================================
