# Olist-E-Commerce-Analytics-Dashboard
An end-to-end data analytics project featuring advanced Power BI dashboards with AI-powered insights, built on Brazilian e-commerce data.
<img width="1130" height="634" alt="Screenshot 2026-02-20 161416" src="https://github.com/user-attachments/assets/6a6b67e1-602b-4a42-b300-9f12b1769372" />
<img width="1128" height="627" alt="Screenshot 2026-02-20 161652" src="https://github.com/user-attachments/assets/0652a9f0-3558-4819-b099-66a3ec8f3262" />
<img width="1119" height="626" alt="Screenshot 2026-02-20 161703" src="https://github.com/user-attachments/assets/aa224581-67db-4d35-819d-9ee6632bf5f5" />

# Olist E-Commerce Analytics Dashboard

> **End-to-end data analytics project** featuring a full Azure cloud pipeline, advanced Power BI dashboards with AI-powered insights, and a production-grade star schema — built on Brazilian e-commerce data.

[![Python](https://img.shields.io/badge/SQL-PostgreSQL-336791?style=flat&logo=postgresql)](https://www.postgresql.org/)
[![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=flat&logo=powerbi)](https://powerbi.microsoft.com/)
[![Azure](https://img.shields.io/badge/Azure-Cloud%20Pipeline-0078D4?style=flat&logo=microsoftazure)](https://azure.microsoft.com/)

---

## 📊 Project Overview

This project demonstrates a **complete, production-grade data analytics workflow** — from raw CSV files in cloud storage all the way through to an interactive Power BI dashboard — featuring:

- **Azure cloud pipeline**: Blob Storage → Azure Data Factory → Azure PostgreSQL
- **9 raw tables** cleaned and loaded via automated ADF pipeline
- **Star schema data warehouse** with 4 dimensions + 1 fact table (112,650 records)
- **40+ DAX measures** for advanced analytics
- **3 interactive dashboard pages** with AI/ML features
- **Advanced visualizations** including decomposition trees, key influencers, and what-if analysis

---

## ☁️ Azure Cloud Extension

This project has been extended with a full **Azure cloud data pipeline** — replacing the local PostgreSQL setup with a production-grade cloud architecture.

### Pipeline Architecture

```
Azure Blob Storage (9 raw CSVs)
          ↓
Azure Data Factory (automated ETL pipeline)
          ↓
Azure PostgreSQL — raw.* (9 tables, 112,650+ records)
          ↓
Azure PostgreSQL — cleaned.* (Star Schema)
          ↓
Power BI Desktop (connected to cloud database)
```

### Azure Services Used

| Service | Role | Free Tier |
|---|---|---|
| Azure Blob Storage | Raw CSV file storage (9 files) | ✅ 5 GB free |
| Azure Data Factory | ETL pipeline with scheduled trigger | ✅ 1K runs/month |
| Azure PostgreSQL Flexible Server | Cloud-hosted star schema database | Credits used |
| Azure Key Vault | Secrets management for credentials | ✅ 10K ops free |
| Azure Monitor | Pipeline failure alerts, cost budgets | ✅ Basic free |

### Key Cloud Concepts Demonstrated

- **Linked Services** — connecting ADF to Blob Storage and PostgreSQL
- **Datasets** — parameterized source/sink data pointers
- **Copy Activities** — automated CSV → PostgreSQL data loading
- **Pre-copy scripts** — TRUNCATE before load to prevent duplicates
- **Pipeline orchestration** — dimension tables loaded before fact table (foreign key order)
- **CTE-based deduplication** — preventing row explosion on multi-row joins
- **Performance indexing** — indexes on all join and filter columns for Power BI speed

### Star Schema (Cloud)

```
dim_customer (99,441)     dim_product (32,951)
       ↓ customer_id              ↓ product_id
       └──────────────────────────┘
                    ↓
              fact_sales (112,650)
                    ↑
       ┌──────────────────────────┐
       ↑ seller_id                ↑ date_key
dim_seller (3,095)          dim_date (634)
```

> **Note:** Power BI Desktop is connected directly to Azure PostgreSQL. Power BI Service publishing requires a Pro license — upgrade path identified for production deployment.

---

## 🎯 Business Problem

Analyze Olist's Brazilian e-commerce marketplace (2016–2018) to:

- Identify sales trends and patterns
- Understand customer behavior and retention
- Optimize delivery operations
- Improve product performance
- Provide actionable business insights

---

## 📸 Dashboard Screenshots

### Page 1: Sales Intelligence Dashboard

![Sales Intelligence Dashboard](images/page1_sales_intelligence.png)

**Features:**
- AI-powered Decomposition Tree for revenue analysis
- ML Key Influencers showing what drives customer satisfaction
- Animated scatter plot with play axis
- What-If parameter for price change simulation
- Conditional formatting with icons and data bars

### Page 2: Geographic & Product Analytics

![Geographic Product Analytics](images/page2_geographic_product.png)

**Features:**
- Interactive state heatmap
- Product performance scatter analysis
- Hierarchical matrix (State → City drill-down)
- Category revenue trends over time
- Top performer identification

### Page 3: Delivery & Operations Performance

![Delivery Operations Performance](images/page3_delivery_operations.png)

**Features:**
- On-time delivery gauge with target tracking
- Review score distribution analysis
- Category satisfaction matrix with conditional formatting
- Delivery performance by state
- NPS Score calculation

---

## 🔑 Key Insights

| Insight | Finding | Action |
|---|---|---|
| Customer Retention Crisis | 100% one-time buyers (99,441 customers = 99,441 orders) | Implement loyalty program and email remarketing |
| Geographic Concentration | SP state = 38.3% of total revenue | Diversify market presence |
| Strong Operations | 91.89% on-time delivery rate exceeds 90% target | Maintain logistics efficiency |
| High Satisfaction | 89% of reviews are 4–5 stars | Leverage for marketing |
| Revenue Decline | Downward trend from 2017 to 2018 | Investigate and implement growth strategy |
| Category Leader | health_beauty dominates with R$1.4M revenue | Expand successful categories |
| Delivery Variance | AP state takes 28 days vs. 21-day average | Optimize remote state logistics |

---

## 🛠️ Technologies Used

### Azure Cloud Stack

| Service | Purpose |
|---|---|
| Azure Blob Storage | Raw data lake for 9 CSV source files |
| Azure Data Factory | Automated ETL pipeline with daily trigger |
| Azure PostgreSQL Flexible Server | Cloud-hosted relational database |
| Azure Key Vault | Secrets and credentials management |
| Azure Monitor | Pipeline alerts and cost budgeting |

### Database & Data Engineering

| Tool | Purpose |
|---|---|
| PostgreSQL 16 (Azure) | Cloud data storage and transformation |
| SQL | Data cleaning, star schema, complex queries |
| CTE optimization | Deduplication before joins (prevents row explosion) |
| Performance indexing | 10 indexes across raw + cleaned schemas |

### Business Intelligence

| Tool | Purpose |
|---|---|
| Power BI Desktop | Dashboard development, connected to Azure PostgreSQL |
| DAX | 40+ calculated measures and KPIs |
| Power Query | Data loading and transformation |

### Advanced Features

| Feature | Implementation |
|---|---|
| AI Visualizations | Decomposition Tree, Key Influencers |
| What-If Parameters | Interactive price simulation |
| Conditional Formatting | 4 types: icons, data bars, colors, fonts |
| Time Intelligence | MoM growth, YTD, running totals |

---

## 📁 Project Structure

```
olist-ecommerce-analytics/
│
├── sql/
│   ├── Datacleaning.sql              # Data cleaning queries
│   ├── Table creation.sql            # Raw schema DDL (raw.*)
│   ├── Starschema.sql                # Star schema DDL (cleaned.*)
│   └── starschema_production.sql     # Optimized production version
│
├── powerbi/
│   └── olistvisusal.pbix             # Power BI dashboard file
│
├── images/
│   ├── page1_sales_intelligence.png
│   ├── page2_geographic_product.png
│   └── page3_delivery_operations.png
│
└── README.md
```

---

## 📊 Data Model

### Dimension Tables

| Table | Rows | Key Columns |
|---|---|---|
| dim_customer | 99,441 | customer_id, segment, value_category, total_orders |
| dim_product | 32,951 | product_id, category, performance, avg_price |
| dim_seller | 3,095 | seller_id, city, state, performance_category |
| dim_date | 634 | date_key, year, month, quarter, day_type |

### Fact Table

| Table | Rows | Key Measures |
|---|---|---|
| fact_sales | 112,650 | item_price, order_total, delivery_days, review_score |

---

## 🔢 Key DAX Measures

### Revenue Metrics

```dax
Total Revenue = ROUND(SUM('cleaned fact_sales'[item_price]), 2)

MoM Revenue Growth % =
VAR CurrentMonth = [Total Revenue]
VAR LastMonth = [Revenue Last Month]
RETURN DIVIDE(CurrentMonth - LastMonth, LastMonth) * 100

Revenue Running Total =
CALCULATE(
    [Total Revenue],
    FILTER(
        ALL('cleaned dim_date'[full_date]),
        'cleaned dim_date'[full_date] <= MAX('cleaned dim_date'[full_date])
    )
)
```

### Customer Metrics

```dax
Customer Retention Rate % =
ROUND(
    DIVIDE([Repeat Customers] + [Loyal Customers], [Total Customers]) * 100,
    2
)

NPS Score =
VAR Promoters = CALCULATE([Total Reviews], review_score >= 4)
VAR Detractors = CALCULATE([Total Reviews], review_score <= 2)
RETURN ROUND(DIVIDE(Promoters - Detractors, [Total Reviews]) * 100, 0)
```

### Operational Metrics

```dax
On-Time Delivery % =
VAR OnTime = CALCULATE([Total Orders], delivered_on_time = TRUE())
VAR Delivered = [Delivered Orders]
RETURN ROUND(DIVIDE(OnTime, Delivered) * 100, 2)
```

---

## 🚀 How to Run This Project

### Option A — Cloud Setup (Azure)

**Prerequisites:**
- Azure account (free trial sufficient)
- pgAdmin installed locally
- Power BI Desktop installed

**Steps:**

1. **Clone the repository**
```bash
git clone https://github.com/Skpkush/Olist-E-Commerce-Analytics-Dashboard.git
cd Olist-E-Commerce-Analytics-Dashboard
```

2. **Download the dataset**
   - Download from [Kaggle — Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
   - Extract all 9 CSV files

3. **Set up Azure resources**
   - Create Azure Blob Storage → upload 9 CSVs to `raw` container
   - Create Azure PostgreSQL Flexible Server
   - Create Azure Data Factory → build pipeline (CSV → PostgreSQL)
   - Run `sql/Table creation.sql` in pgAdmin connected to Azure PostgreSQL
   - Run ADF pipeline once to load raw data
   - Run `sql/starschema_production.sql` block by block to build star schema

4. **Connect Power BI Desktop**
   - Open `powerbi/olistvisusal.pbix`
   - Update data source → Azure PostgreSQL server
   - Refresh data

### Option B — Local Setup

**Prerequisites:**
- PostgreSQL 14+ installed locally
- Power BI Desktop installed

**Steps:**

1. Clone repository and download dataset (same as above)

2. **Set up local PostgreSQL**
```sql
CREATE DATABASE OlistDB;
CREATE SCHEMA raw;
CREATE SCHEMA cleaned;
```

3. Run `sql/Table creation.sql` → import CSVs → run `sql/starschema_production.sql`

4. Open `powerbi/olistvisusal.pbix` → connect to local PostgreSQL → refresh

---

## 📈 Dashboard Features

### Advanced Visualizations

| Visual | Purpose |
|---|---|
| Decomposition Tree | AI-powered hierarchical revenue analysis |
| Key Influencers | ML-driven customer satisfaction factors |
| Play Axis | Animated time-series scatter plot |
| What-If Parameters | Interactive price change simulation |
| Conditional Formatting | Multi-level visual encoding |

### Interactive Elements

- **3 Synced Slicers**: Date range, Product category, Customer state
- **Cross-filtering**: Click any visual to filter others
- **Drill-through**: Right-click for detailed views
- **Tooltips**: Hover for additional metrics

---

## 💡 Skills Demonstrated

### Cloud & Data Engineering
✅ Azure cloud pipeline design and implementation
✅ Azure Data Factory — Linked Services, Datasets, Copy Activities
✅ Azure Blob Storage — containers, file management
✅ Azure PostgreSQL — cloud database hosting and management
✅ ETL pipeline orchestration with dependency management
✅ SQL performance optimization — CTEs, indexes, deduplication

### Business Intelligence
✅ Star schema dimensional modeling
✅ Complex DAX calculations and time intelligence
✅ Advanced Power BI visualizations
✅ AI/ML feature implementation (Key Influencers, Decomposition Tree)
✅ KPI definition and tracking

### Analytical & Business Skills
✅ E-commerce domain understanding
✅ Customer retention strategy analysis
✅ Operational efficiency measurement
✅ Geographic market analysis
✅ Actionable insight generation

---

## 📊 Dataset Information

| Property | Detail |
|---|---|
| Source | Kaggle — Brazilian E-Commerce Public Dataset by Olist |
| Time Period | September 2016 – October 2018 |
| Orders | 99,441 |
| Order Items | 112,650 |
| Customers | 99,441 |
| Products | 32,951 |
| Sellers | 3,095 |
| Geographic Coverage | 27 Brazilian states, 4,110+ cities |

---

## 🔮 Future Enhancements

- [ ] Add predictive analytics — customer churn prediction model
- [ ] Implement Azure Synapse Analytics for serverless SQL queries on raw files
- [ ] Add Azure Monitor alerts for pipeline failures
- [ ] Develop Python integration for advanced ML models
- [ ] Add automated email reports via Power Automate
- [ ] Create drill-through pages for detailed customer analysis
- [ ] Power BI Service deployment (requires Pro license)

---

## 📞 Contact

**Sumit Prajapat** | Data Analyst

📧 [sumitkprajapat@gmail.com](mailto:sumitkprajapat@gmail.com)
💼 [LinkedIn](https://www.linkedin.com/in/sumit-k-prajapat/)
🐙 [GitHub](https://github.com/Skpkush)

---

## 🙏 Acknowledgments

- Dataset provided by Olist and made available on Kaggle
- Microsoft Azure documentation and Power BI community
- SQL and DAX documentation resources

---

*Built as part of a senior-level data analyst portfolio demonstrating end-to-end cloud data engineering, SQL, and business intelligence skills.*
