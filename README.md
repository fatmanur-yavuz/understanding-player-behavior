# Understanding Player Behavior: Game Analytics & Product Case Study

## 📌 Case Study Overview
This project models and analyzes player engagement, onboarding funnel efficiency, retention rates, monetization performance, level friction points, and feature adoption for a mobile puzzle game using synthetic event logs (synthetic_player_events.csv).

Rather than relying on pre-assumed outcomes, this case study applies an end-to-end analytical framework to uncover organic player behavior, evaluate key product metrics, and construct data-driven product hypotheses.

---

## 🛠️ Methodology & Tech Stack
- *Python (Pandas, Matplotlib, Seaborn):* Synthetic behavioral data pipeline generation and Exploratory Data Analysis (EDA) in Google Colab.
- *SQL (PostgreSQL / BigQuery Dialect):* Analytical modeling covering Activation, Retention, Monetization, Progression, and Feature Engagement.
- *Git & GitHub:* Code repository management and technical documentation.

---

## 📊 Analytical Framework & Core Metrics
The analytical layer in queries.sql evaluates player activity across five key dimensions:

1. *Activation & Funnel Drop-off:* Measuring progression conversion from install -> tutorial_start -> tutorial_complete.
2. *User Retention Metrics:* Tracking Cohort Retention (Day 1, Day 7, Day 30) to evaluate mid-to-long term player stickiness.
3. *Monetization & Channel Efficiency:* Assessing Acquisition Channels based on Payer Conversion (%), ARPU (Average Revenue Per User), and ARPPU.
4. *Level Friction & Bottlenecks:* Pinpointing high fail-rate levels that signal potential churn risk.
5. *Feature Adoption:* Comparing feature unlock counts against active feature usage (e.g., Daily Challenges, Streaks).

---

## 📂 Repository Structure
```text
├── synthetic_player_events.csv   # Primary behavioral dataset (2,000 players, 30-day window)
├── generate_dataset.py           # Python script used for generating behavioral event logs
├── queries.sql                   # SQL queries for Activation, Retention, Level Friction & Monetization
└── README.md                     # Technical framework and case study overview
