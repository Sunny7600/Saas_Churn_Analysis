# SaaS Customer Churn Analysis & Retention Dashboard

An end-to-end data analytics project that investigates why customers cancel their subscriptions at a B2B SaaS company, quantifies the revenue impact, and flags at-risk accounts before they leave.

**Tools:** Python (Pandas, NumPy) · MySQL · Power BI

---

## Business Problem

A B2B SaaS company is losing customers every month. Even though new customers keep joining, cancellations are eroding Monthly Recurring Revenue (MRR).

**Goal:** Analyze usage data, support logs and payment patterns to:

1. Identify the main reasons customers cancel.
2. Identify high-risk active customers early, so the Customer Success team can step in and retain them.

---

## Project Workflow

| Step | Tool | Output |
|------|------|--------|
| 1. Data cleaning | Python (Pandas) | `Saas_Churn_Cleaned_Data.csv` |
| 2. Analysis & risk scoring | MySQL | `Saas_Churn_Analysis.sql` |
| 3. Visualization | Power BI | `Saas_Churn_Dashboard.pbix` / `.pdf` |

---

## Repository Structure

```
├── Saas_Churn_Raw_Dataset.csv        # Raw data (44,440 rows)
├── Saas_Churn_Data_Cleaning.ipynb    # Data cleaning notebook
├── Saas_Churn_Cleaned_Data.csv       # Cleaned data (43,912 rows)
├── Saas_Churn_Analysis.sql           # MySQL schema + analysis queries
├── Saas_Churn_Dashboard.pbix         # Power BI dashboard
├── Saas_Churn_Dashboard.pdf          # Dashboard export
└── README.md
```

---

## Dataset

- **Size:** 43,912 customers after cleaning, 24 columns
- **Signup period:** January 2024 – December 2025
- **Countries:** India, USA, UK, Germany, Australia, Singapore, UAE
- **Industries:** Education, Finance, Healthcare, IT Services, Logistics, Manufacturing, Retail

| Category | Columns |
|----------|---------|
| Customer profile | `Customer_Id`, `Signup_Date`, `Industry`, `Company_Size`, `Country`, `Acquisition_Channel` |
| Subscription | `Plan_Type`, `Billing_Cycle`, `Seats_Purchased`, `Seats_Active`, `Mrr`, `Payment_Method` |
| Product usage | `Onboarding_Completed`, `Avg_Monthly_Logins`, `Features_Used_Count`, `Days_Since_Last_Login` |
| Support | `Support_Tickets_90D`, `Avg_Resolution_Hours`, `Csat_Score` |
| Payments | `Failed_Payments_6M` |
| Outcome | `Customer_Status`, `Churn_Date`, `Tenure_Months`, `Churn_Reason` |

---

## Data Cleaning (Python)

Performed in `Saas_Churn_Data_Cleaning.ipynb`:

- Removed **440 duplicate rows**
- Standardized column names to `Title_Case`
- Fixed inconsistent text in `Plan_Type`, `Country` and `Payment_Method` (trimming, casing, e.g. `Usa`/`U.S.A` → `USA`, `Upi` → `UPI`, underscores removed)
- Filled missing `Industry` and `Acquisition_Channel` with `Unknown`
- Filled missing `Churn_Reason` for churned customers with `Not Recorded`
- Set missing `Avg_Resolution_Hours` to 0 where tickets were raised but no resolution time was logged
- Parsed mixed-format dates and **removed 88 rows where `Churn_Date` was earlier than `Signup_Date`**
- Recalculated `Tenure_Months` (signup to churn date, or to 30 Nov 2025 for active customers)

**Result:** 44,440 raw rows → 43,912 clean rows, with no duplicate customer IDs.

---

## Analysis (SQL)

`Saas_Churn_Analysis.sql` creates the `saas_churn` table in a `saas_db` database and runs the following analyses:

1. KPI summary (customer and revenue churn)
2. Churn drivers and revenue lost per reason
3. Product engagement (logins, features used, inactivity)
4. Support experience and CSAT
5. **Churn risk scoring** for active accounts (High / Medium / Low)
6. Tenure and onboarding cohort analysis
7. Plan type churn and revenue impact
8. Support ticket volume and escalation
9. Seat utilization
10. Onboarding completion impact
11. Billing cycle churn
12. Company size churn
13. Onboarding × billing cycle combined risk

**Risk scoring logic (active customers):**

| Level | Condition |
|-------|-----------|
| High Risk | Inactive > 30 days, **or** < 3 logins/month, **or** ≥ 2 failed payments, **or** CSAT ≤ 2 |
| Medium Risk | Inactive 15–30 days, **or** CSAT = 3 |
| Low Risk | Everything else |

Results are ordered by MRR so the highest-value at-risk accounts are contacted first.

---

## Key Findings

### Headline numbers

| Metric | Value |
|--------|-------|
| Total customers | 43,912 |
| Churned customers | 6,559 |
| **Customer churn rate** | **14.94%** |
| Total MRR | $137.39M |
| MRR lost | $14.44M |
| **MRR churn rate** | **10.51%** |

### What drives churn

- **Top reasons:** Low Product Usage (32.37%) and Pricing Too High (22.73%) together account for over 55% of cancellations.
- **Early tenure is the danger zone:** churn peaks at 52.35% in Month 1, then 37.84% in Month 2 and 25.17% in Month 3, settling to about 10% by Month 5.
- **Onboarding matters most:** customers who did not complete onboarding churn at 39.5% vs. 8.0% for those who did (about 5x higher).
- **Low engagement:** churned users averaged 10.62 monthly logins vs. 22.52 for active users, used 4.22 features vs. 6.84, and were inactive for 17.81 days vs. 7.68.
- **Seat shelfware:** seat utilization is 57.02% for churned customers vs. 77.18% for active ones.
- **Support experience:** churned customers had lower CSAT (2.85 vs. 3.43) and slower resolution (13.46 vs. 10.99 hours). Churn rises from 12.05% with 0 tickets to 22.57% with 4+ tickets.
- **Billing cycle:** Monthly plans churn at 17.5% vs. 10.2% for Annual.
- **Company size:** 1–10 employee companies churn at 18.1% vs. 9.0% for 1000+ employees.

### Plan type: volume vs. revenue

| Plan | Churn rate | Observation |
|------|-----------|-------------|
| Basic | 17.10% | Highest churn rate (3,311 customers lost) |
| Pro | 15.14% | 2,599 customers lost |
| Enterprise | 8.80% | Lowest churn rate, but the **largest revenue loss ($7.31M)** |

---

## Recommendations

1. **Fix onboarding first.** Make guided setup and a check-in call within the first 30 days standard, focusing on Monthly-billed customers who haven't completed onboarding.
2. **Use the risk score operationally.** Give Customer Success a weekly list of High Risk accounts sorted by MRR.
3. **Drive feature and seat adoption.** Trigger outreach or downsell/training offers when seat utilization or feature usage is low.
4. **Add SLAs for multi-ticket accounts.** Prioritize accounts with 4+ tickets and slow resolution times.
5. **Push Monthly → Annual.** Offer incentives to move Monthly customers onto Annual contracts.
6. **Segment retention by size.** Use low-touch automation for small accounts and dedicated account managers for Enterprise.

---

## Skills Demonstrated

Data cleaning and validation · SQL (aggregations, window functions, `CASE` logic, cohort analysis) · customer risk scoring · KPI design · Power BI dashboarding · translating data into business recommendations

---

## Author

**Sunny Yadav**
