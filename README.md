# Olist-E-Commerce-Analytics-Dashboard
An end-to-end data analytics project featuring advanced Power BI dashboards with AI-powered insights, built on Brazilian e-commerce data.
<img width="1130" height="634" alt="Screenshot 2026-02-20 161416" src="https://github.com/user-attachments/assets/6a6b67e1-602b-4a42-b300-9f12b1769372" />
<img width="1128" height="627" alt="Screenshot 2026-02-20 161652" src="https://github.com/user-attachments/assets/0652a9f0-3558-4819-b099-66a3ec8f3262" />
<img width="1119" height="626" alt="Screenshot 2026-02-20 161703" src="https://github.com/user-attachments/assets/aa224581-67db-4d35-819d-9ee6632bf5f5" />


📊 Project Overview
This project demonstrates a complete data analytics workflow from data cleaning through to interactive dashboard creation, featuring:

9 raw tables cleaned and transformed using PostgreSQL
Star schema data warehouse with 4 dimensions + 1 fact table
40+ DAX measures for advanced analytics
3 interactive dashboard pages with AI/ML features
Advanced visualizations including decomposition trees, key influencers, and what-if analysis

🎯 Business Problem
Analyze Olist's Brazilian e-commerce marketplace (2016-2018) to:

Identify sales trends and patterns
Understand customer behavior and retention
Optimize delivery operations
Improve product performance
Provide actionable business insights

📸 Dashboard Screenshots
Page 1: Sales Intelligence Dashboard
<img width="1130" height="634" alt="Screenshot 2026-02-20 161416" src="https://github.com/user-attachments/assets/6e012918-ab0b-41d5-9f1e-da89d074c0b4" />

Features:

AI-powered Decomposition Tree for revenue analysis
ML Key Influencers showing what drives customer satisfaction
Animated scatter plot with play axis
What-If parameter for price change simulation
Conditional formatting with icons and data bars

Page 2: Geographic & Product Analytics
<img width="1128" height="627" alt="Screenshot 2026-02-20 161652" src="https://github.com/user-attachments/assets/f0e7d220-91a4-4423-8f58-292aef8f00ba" />

Features:

Interactive state heatmap
Product performance scatter analysis
Hierarchical matrix (State → City drill-down)
Category revenue trends over time
Top performer identification

Page 3: Delivery & Operations Performance
<img width="1119" height="626" alt="Screenshot 2026-02-20 161703" src="https://github.com/user-attachments/assets/5ccc2844-41ce-4ff0-8515-3ed83cd37de9" />

Features:

On-time delivery gauge with target tracking
Review score distribution analysis
Category satisfaction matrix with conditional formatting
Delivery performance by state
NPS Score calculation

## 📊 How to View Dashboard

**Option 1: Download .pbix File**
1. Download [Olist_Ecommerce_Analytics.pbix](./Olist_Ecommerce_Analytics.pbix)
2. Open with Power BI Desktop
3. Connect to PostgreSQL (optional) or view offline

**Option 2: View Screenshots**
- [Page 1: Sales Intelligence](#page-1-sales-intelligence-dashboard)
- [Page 2: Geographic & Product](#page-2-geographic--product-analytics)
- [Page 3: Delivery & Operations](#page-3-delivery--operations-performance)

🔑 Key Insights
Business Insights Discovered:

Customer Retention Crisis: 100% of customers are one-time buyers (98,666 customers = 98,666 orders)
Recommendation: Implement loyalty program and email remarketing


Geographic Concentration Risk: SP state accounts for 38.3% of total revenue
Recommendation: Diversify market presence across other states


Strong Operational Performance: 91.89% on-time delivery rate exceeds 90% target
Strength: Efficient logistics operations


High Customer Satisfaction: 89% of reviews are 4-5 stars (63K+ five-star reviews)
Strength: Quality products and service


Revenue Decline Trend: Clear downward trend visible from 2017 to 2018
Alert: Investigate causes and implement growth strategies


Category Performance: health_beauty dominates with R$1.4M revenue
Opportunity: Expand successful categories


Delivery Variance: AP state takes 28 days vs. 21-day average
Improvement Area: Optimize logistics for remote states



🛠️ Technologies Used
Database & Data Engineering

PostgreSQL 16: Data storage and transformation
SQL: Data cleaning, star schema creation, complex queries

Business Intelligence

Power BI Desktop: Dashboard development
DAX: 40+ calculated measures and KPIs
Power Query: Data loading and transformation

Advanced Features

AI Visualizations: Decomposition Tree, Key Influencers
What-If Parameters: Interactive scenario analysis
Conditional Formatting: 4 types (icons, data bars, colors, fonts)
Time Intelligence: MoM growth, YTD, running totals

📁 Project Structure 
'''
olist-ecommerce-analytics/
│
├── data/
│   └── raw/                       # Original Olist dataset (9 CSV files)
│
├── sql/
│   ├── data_cleaning.sql           # Data cleaning queries
│   └── star_schema_creation.sql    # Star schema DDL
│
├── powerbi/
│   └── Olist_Ecommerce_Analytics.pbix   # Power BI dashboard file
│
├── screenshots/
│   ├── page1_sales_intelligence.png
│   ├── page2_geographic_product.png
│   └── page3_delivery_operations.png
│
└── README.md
'''

📊 Data Model Star Schema Design

dim_customer (99,442)
↓ customer_id ↓
dim_product (32,951) → fact_sales (112,987) ← dim_date (634)
↑ product_id          seller_id ↑
                      ↑
                      dim_seller (3,096)

Dimension Tables:

dim_customer: Customer demographics and behavior
dim_product: Product catalog with performance metrics
dim_seller: Seller information and ratings
dim_date: Time dimension with full hierarchy

Fact Table:

fact_sales: Transactional data with 112,987 records

🔢 Key Metrics & DAX Measures
Revenue Metrics
daxTotal Revenue = ROUND(SUM('cleaned fact_sales'[item_price]), 2)

MoM Revenue Growth % = 
VAR CurrentMonth = [Total Revenue]
VAR LastMonth = [Revenue Last Month]
RETURN
    DIVIDE(CurrentMonth - LastMonth, LastMonth) * 100

Revenue Running Total = 
CALCULATE(
    [Total Revenue],
    FILTER(
        ALL('cleaned dim_date'[full_date]),
        'cleaned dim_date'[full_date] <= MAX('cleaned dim_date'[full_date])
    )
)
Customer Metrics
daxCustomer Retention Rate % = 
ROUND(
    DIVIDE(
        [Repeat Customers] + [Loyal Customers],
        [Total Customers]
    ) * 100,
    2
)

NPS Score = 
VAR Promoters = CALCULATE([Total Reviews], review_score >= 4)
VAR Detractors = CALCULATE([Total Reviews], review_score <= 2)
RETURN
    ROUND(DIVIDE(Promoters - Detractors, [Total Reviews]) * 100, 0)
Operational Metrics
daxOn-Time Delivery % = 
VAR OnTime = CALCULATE([Total Orders], delivered_on_time = TRUE())
VAR Delivered = [Delivered Orders]
RETURN
    ROUND(DIVIDE(OnTime, Delivered) * 100, 2)
🚀 How to Use This Project
Prerequisites

PostgreSQL 14+ installed
Power BI Desktop (latest version)
4GB RAM minimum

Setup Instructions

Clone the Repository

bashgit clone https://github.com/yourusername/olist-ecommerce-analytics.git
cd olist-ecommerce-analytics

Download the Dataset

Download from Kaggle: Brazilian E-Commerce Public Dataset by Olist
Extract to data/raw/ folder


Set Up PostgreSQL Database

sql-- Create database
CREATE DATABASE Olist_db;

-- Create schema
CREATE SCHEMA cleaned;

-- Load raw data into tables (use pgAdmin or COPY command)
-- Run data cleaning queries from sql/data_cleaning.sql
-- Run star schema creation from sql/star_schema_creation.sql

Open Power BI Dashboard

Open powerbi/Olist_Ecommerce_Analytics.pbix
Update data source connection to your PostgreSQL instance
Refresh data



📈 Dashboard Features
Advanced Visualizations

Decomposition Tree: AI-powered hierarchical analysis
Key Influencers: ML-driven factor analysis
Play Axis: Animated time-series scatter plot
What-If Parameters: Interactive price simulation
Conditional Formatting: Multi-level visual encoding

Interactive Elements

3 Synced Slicers: Date range, Product category, Customer state
Cross-filtering: Click any visual to filter others
Drill-through: Right-click for detailed views
Tooltips: Hover for additional metrics

💡 Skills Demonstrated
Technical Skills

✅ SQL data cleaning and transformation
✅ Star schema dimensional modeling
✅ Complex DAX calculations
✅ Advanced Power BI visualizations
✅ AI/ML feature implementation
✅ Data warehouse design

Analytical Skills

✅ Business problem identification
✅ KPI definition and tracking
✅ Trend analysis
✅ Customer segmentation
✅ Performance benchmarking
✅ Actionable insights generation

Business Acumen

✅ E-commerce domain understanding
✅ Customer retention strategies
✅ Operational efficiency analysis
✅ Geographic market analysis
✅ Product portfolio optimization

📊 Dataset Information
Source: Kaggle - Brazilian E-Commerce Public Dataset by Olist
Time Period: September 2016 - October 2018
Size:

9 tables
112,987 order items
98,666 orders
98,666 customers
32,951 products
3,096 sellers

Geographic Coverage: 27 Brazilian states, 4,110 cities
🎓 Learning Outcomes
Through this project, I developed expertise in:

Building production-ready data pipelines
Designing efficient dimensional models
Creating interactive business intelligence dashboards
Implementing AI/ML visualizations
Deriving actionable business insights from data
Presenting complex analyses to stakeholders

🔮 Future Enhancements

 Add predictive analytics (customer churn prediction)
 Implement real-time data refresh
 Create mobile-optimized views
 Add natural language Q&A with Power BI Q&A
 Develop Python integration for advanced ML models
 Add automated email reports
 Create drill-through pages for detailed analysis

📞 Contact
Sumit Prajapat

📧 Email: sumitkprajapat@gmail.com

🙏 Acknowledgments

Dataset provided by Olist and made available on Kaggle
Power BI community for inspiration and best practices
SQL and DAX documentation resources
