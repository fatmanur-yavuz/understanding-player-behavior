# 🎮 Understanding Player Behavior: From Player Motivation to Product Decisions

> ⚠️ *Synthetic Case Study*  
> This project uses a fully synthetic dataset created for educational and portfolio purposes. It models real-world event log structures and behavioral mechanics without using proprietary data from any actual game or company.

---

## 📌 Overview
This case study explores how player behavior can be analyzed and translated into product questions, hypotheses, and potential experiments.

Rather than pre-labeling player segments, this project simulates raw event logs driven by *simulated behavioral tendencies* and explores natural behavioral patterns using *SQL* and *Python*.

The goal is not simply to measure whether players stay in a game, but to understand:
- What makes players start playing?
- What behaviors are associated with continued engagement?
- Why do some players return while others leave?
- How does progression and feature discovery relate to player behavior?
- What behavioral patterns may be associated with monetization?
- How can these insights inform product decisions?

---

## 🎯 Product Question
> *What makes players start, engage with, return to, and spend in a game — and how can a product team use these insights to create sustainable player value?*

---

## 🧠 Analytical Approach
The project follows a product-oriented analytical workflow:

Observe → Analyze → Interpret → Hypothesize → Experiment → Measure

### Key Analytical Pillars
- *Activation & Onboarding:* What early behaviors during the first session correlate with long-term retention?
- *Progression & Friction:* Are there points in the progression journey where player engagement or return behavior changes noticeably?
- *Engagement Patterns:* How does feature discovery and active feature usage (e.g., Daily Challenges, Streaks) relate to player retention?
- *Monetization Mechanics:* Does monetization occur alongside sustained engagement, or independently of it?

---

## 🗺️ Player Journey Framework
The simulated player journey tracks behavioral signals across:

Discover → Start → Engage → Progress → Return → Retain → Monetize

---

## 📊 Dataset & Event Schema
The dataset represents raw event logs (synthetic_player_events.csv) covering *2,000 players* across a *30-day observation period*.

### Attribute Schema
| Attribute | Type | Description |
| :--- | :--- | :--- |
| player_id | STRING | Unique player identifier (P0001 - P2000) |
| timestamp | DATETIME | Precise event timestamp |
| session_id | STRING | Unique session identifier (S_P0001_1) |
| event_name | STRING | Type of event triggered |
| level | INTEGER | Player level at event time (0 = Onboarding/Menu) |
| attempt_number | INTEGER | Level attempt counter |
| feature_name | STRING | Name of unlocked/used feature (Daily_Challenge, Streak, etc.) |
| purchase_amount | FLOAT | In-app purchase value in USD ($) |
| acquisition_channel | STRING | Attribution channel (Organic, Paid_Meta, Paid_Google, Referral) |

### Event Catalog
- *Onboarding:* install, tutorial_start, tutorial_complete
- *Core Loop:* session_start, session_end, level_start, level_complete, level_fail
- *Engagement Features:* feature_unlocked, feature_used, booster_used
- *Monetization:* purchase
