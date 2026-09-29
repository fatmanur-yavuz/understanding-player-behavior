## 📌 Case Study Overview
This project models and analyzes player engagement, onboarding funnel efficiency, retention rates, monetization performance, level friction points, and feature adoption for a mobile puzzle game using synthetic event logs (synthetic_player_events.csv).

---

## 📈 Key Data Findings & Executive Summary

Based on SQL analytics executed across 2,000 players over a 30-day window:

### 1. Onboarding & Activation Funnel
- *Total Installs:* 2,000 players
- *Tutorial Started:* 2,000 players (100.0% conversion)
- *Tutorial Completed:* 1,770 players (*88.5% completion rate*)
- Product Insight: The onboarding tutorial has low friction, successfully guiding 88.5% of new installs to core gameplay readiness.

### 2. Player Retention Dynamics
- *Day 1 Retention (D1):* *82.2%*
- *Day 7 / Day 29 Retention:* *0.0%*
- Product Insight: While initial Day 1 engagement is exceptionally strong (82.2%), long-term retention drops sharply before Day 7. Retention strategies must focus on mid-term progression loops and daily engagement triggers between Day 2 and Day 6.

### 3. Acquisition Channels & Revenue Distribution
- *Total Purchase Events:* 1,053 transactions
- *Channel Volume:* Organic (119.7k events), Paid Meta (91.5k events), Paid Google (65.4k events), Referral (28.7k events).

---

## 🛠️ Methodology & Tech Stack
- *Python (Pandas, DuckDB):* Synthetic behavioral data pipeline generation and SQL-based Exploratory Data Analysis (EDA) in Google Colab.
- *SQL (DuckDB Dialect):* 18-step analytical framework covering Activation, Retention, Monetization, Progression, and Feature Engagement.
- *Git & GitHub:* Code repository management and technical documentation.

---

## 📂 Repository Structure
```text
├── synthetic_player_events.csv   # Primary behavioral dataset (2,000 players, 30-day window)
├── generate_dataset.py           # Python script used for generating behavioral event logs
├── queries.sql                   # 18-step SQL analytics framework
└── README.md                     # Technical framework and case study overview
