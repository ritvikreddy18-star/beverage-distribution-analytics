Beverage Distribution Performance & Channel Analytics
SQL (PostgreSQL) · Tableau Public · Distribution Analytics · Channel Performance

Overview
This project analyzes 30,000 wholesale beverage distribution transactions across 290 suppliers, 15,732 SKUs, and 8 product categories. The analysis identifies high-value supplier relationships, underperforming inventory, channel efficiency gaps, and monthly demand patterns — translating raw sales data into prioritized business recommendations.
The central question driving the analysis: which products and suppliers generate the most revenue, and which sales channel — retail or warehouse — delivers the highest return on inventory investment?

Dataset
Source: Montgomery County, Maryland — Retail & Warehouse Sales (Open Government Data)
Records: 30,000 transactions
Period: January 2020 – September 2020
Columns: Year, Month, Supplier, Item Code, Item Description, Item Type, Retail Sales, Retail Transfers, Warehouse Sales
Categories: Wine, Beer, Liquor, Non-Alcohol, Kegs, STR Supplies, REF, Dunnage

Tools
PostgreSQL for all data cleaning, transformation, segmentation, and business impact analysis. Tableau Public for interactive dashboard development.

Analysis Structure
The SQL script follows a top-down analytical framework structured across 9 sections.
Section 1 covers data quality validation — checking for nulls, negative values, and record completeness before any analysis begins. Section 2 establishes baseline KPIs across channels and categories. Sections 3 and 4 break down channel and supplier performance, identifying concentration risk and tier classifications. Section 5 classifies product performance across all SKUs. Section 6 runs monthly trend analysis with month-over-month growth rates using window functions. Section 7 applies revenue-based segmentation to both suppliers and SKUs. Section 8 runs Pareto analysis to quantify how many SKUs drive 80% of revenue and flags dead stock inventory. Section 9 creates clean Tableau-ready views for the dashboard.

Key Findings
Warehouse channel accounts for 80.1% of total revenue ($836K) while retail represents 19.9% ($208K) — confirming this is a wholesale-first business where B2B distribution drives the majority of volume.
Beer dominates total revenue at $757K — nearly 4x higher than Wine ($179K) and 8x higher than Liquor ($90K) — driven almost entirely through the warehouse channel at 92% warehouse share.
Liquor is the most retail-dependent category at 90% retail channel share, suggesting a fundamentally different go-to-market model compared to Beer and Kegs which are wholesale-driven.
The top 3 suppliers — Crown Imports ($192K), Anheuser Busch ($150K), and Miller Brewing ($133K) — account for 45% of total distribution revenue, representing significant concentration risk in the supplier portfolio.
July was the single highest-revenue month at $515K — more than 3x the revenue of January ($364K) — indicating strong seasonal demand concentration in summer months.
Wine has 9,805 unique SKUs with many showing zero movement across both channels, pointing to a long-tail inventory problem tying up working capital.

Strategic Recommendations
Consolidate the supplier base around Tier 1 partners. With the top 10 suppliers generating 70%+ of total revenue, the bottom 200+ suppliers represent high administrative overhead relative to commercial contribution.
Address dead stock through an active SKU discontinuation policy. SKUs with zero retail and warehouse movement over a rolling 3-month window should trigger mandatory review — particularly in Wine where SKU count is highest.
Invest in Liquor category expansion. Liquor delivers the highest retail channel revenue per SKU and shows balanced dual-channel performance, representing the clearest organic growth opportunity.
Pre-position inventory ahead of the summer peak. July is the strongest revenue month by a significant margin — building stock 6–8 weeks ahead of June for high-velocity Beer and Keg SKUs would reduce stockout risk.

Dashboard
The dashboard presents five KPI cards (Total Revenue, Retail Sales, Warehouse Sales, Active Suppliers, Active SKUs), a channel mix breakdown by category, top 20 supplier ranking, SKU performance segmentation, monthly revenue trend with channel split, and a category-level revenue heatmap. All views are filterable by product category and month.

Project Structure
beverage-distribution-analytics/
│
├── analysis.sql       # Full SQL analysis — 9 sections, 25+ queries
└── README.md          # Project documentation

SQL · PostgreSQL · Tableau Public · Channel Analytics · Supplier Segmentation · Revenue Analysis · Distribution Performance
