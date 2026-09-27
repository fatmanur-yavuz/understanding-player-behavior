# Understanding Player Behavior: Game Analytics & Funnel Optimization Case Study

## 📌 Executive Summary
This case study focuses on analyzing player engagement, onboarding funnel drop-offs, channel monetization efficiency, level failure friction points, and feature adoption rates for a mobile puzzle game. Using synthetic event data (synthetic_player_events.csv), the primary objective is to translate raw event data into actionable Product Management insights and data-driven product recommendations.

---

## 🛠️ Tech Stack & Methodology
- *SQL (PostgreSQL / BigQuery syntax):* Funnel modeling, user retention metrics, channel performance calculations, and friction point identification.
- *Python (Pandas, Matplotlib, Seaborn):* Exploratory Data Analysis (EDA), distribution visualization, and data pipeline processing in Google Colab.
- *Git & GitHub:* Version control, project documentation, and structured analytical reporting.

---

## 📊 Key Findings & Analysis Summary

### 1. Tutorial Onboarding Funnel
- *Highest Drop-off:* Significant user friction was identified between install and tutorial_start.
- *Completion Rate:* Players who reach tutorial_start show high intent, but optimizing initial loading speeds and early guidance is critical to improving overall onboarding retention.

### 2. Channel Monetization Performance
- *ARPU & Conversion:* Acquisition channels were evaluated based on paying player conversion (payer_conversion_pct) and Average Revenue Per User (ARPU).
- *ROI Strategy:* Recommended reallocating marketing budget toward high-LTV channels while optimizing onboarding flows for low-converting performance marketing sources.

### 3. Level Friction & Churn Risk
- *Bottleneck Levels:* Specific mid-game levels exhibited abnormally high failure rates (fail_rate_pct > 60%).
- *Player Churn Impact:* High failure counts on these specific levels directly correlated with session abandonment. Dynamic difficulty adjustment (DDA) or targeted booster prompts are recommended for these friction points.

### 4. Feature Adoption Rate
- *Unlocks vs. Usage:* Tracked engagement across special mechanics (e.g., Daily Challenges, Streaks).
- *Engagement Insight:* Features with lower adoption rates require improved UI visibility and early-game contextual tutorials to drive daily habit formation.

---

## 💡 Strategic Product Recommendations
1. *Onboarding Optimization:* Simplify early tutorial steps and introduce dynamic skip/fast-forward options to minimize drop-off before tutorial_complete.
2. *Dynamic Balancing:* Implement difficulty smoothing algorithms for bottleneck levels to maintain player flow state and reduce early churn.
3. *Monetization Alignment:* Tailor rewarded video placement and starter pack offers specifically around high-friction levels where player intent to progress is highest.

---

## 📂 Repository Structure
```text
├── synthetic_player_events.csv   # Primary dataset containing player behavioral events
├── queries.sql                   # Production-ready SQL queries for funnel & channel analysis
├── Analytics_Notebook.ipynb      # Google Colab notebook containing Python EDA & visualizations
└── README.md                     # Project overview and strategic insights
