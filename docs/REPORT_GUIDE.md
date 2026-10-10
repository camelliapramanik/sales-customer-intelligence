# Report walkthrough

The supplied PBIX has four visible analytical pages and one hidden methodology page. Each visible page uses a 1920 × 1080 canvas, a blue background, KPI cards, page navigation, and an information button linked to the About page. This inventory was read from the actual report definition; it is not a proposed design or a screenshot.

## Executive Overview

**Purpose:** establish the scale, trend, and distribution of sales.

Six cards display Total Sales, Total Profit, Profit Margin %, Total Orders, Total Customers, and Average Order Value. A monthly line chart provides the time trend, bar charts compare territories and product categories, and a donut chart shows Online/Reseller channel mix.

**Slicer fields:** calendar year, sales channel, territory name, and product category.

Start with all filters cleared, then select a year and channel to compare their contribution. Sales is discounted revenue excluding order tax and freight. Profit is estimated using standard costs.

## Customer Analytics

**Purpose:** distinguish the historical customer base from recent purchasing activity.

Cards show Customer Base, Active Customers, Inactive Customers, Active Customer Rate, Repeat Customer Rate, and Avg Sales per Customer. A line chart tracks New Customers. A bar chart and detail table are configured for the top 10 customer names by lifetime sales. The table includes customer type, lifetime sales/orders, last purchase date, days since purchase, activity status, and rank.

**Slicer fields:** calendar year, territory name, sales channel, and customer type.

Customer Base and lifetime measures include purchases through the selected analysis date. Avg Sales per Customer uses sales and distinct purchasing customers in the current period. These are different populations and should not be interpreted interchangeably.

Customer names are not unique in the sample. Visuals grouped only by name can combine accounts even though the model relates tables by CustomerID. See [validation notes](VALIDATION.md) before treating name-based rankings as account-level results.

## Product Performance

**Purpose:** compare product scale, price, discounting, and estimated profitability.

Cards show Total Sales, Total Profit, Profit Margin %, Total Quantity Sold, Avg Selling Price, and Discount Rate %. Visuals include the top 10 products by sales, top 10 by profit, sales by subcategory, and top 10 subcategories by profit margin. The product table includes name/category/subcategory, sales, quantity, profit, margin, selling price, contribution, and sales rank.

**Slicer fields:** calendar year, product category, product subcategory, and sales channel.

Compare a sales leader with a profit leader. Contribution and rank use the current selection context; they are not fixed global rankings. Product contribution removes only the product-name filter, so category/subcategory context can affect the denominator.

## Territory & Sales Performance

**Purpose:** compare regions and assigned salesperson performance.

Cards display Total Sales, Total Profit, Profit Margin %, Sales YoY % Comparable, Active Salespeople, and Avg Sales per Salesperson (displayed as Avg Reseller Sales / Salesperson). Visuals show territory sales, territory YoY growth, regional channel mix, top salespeople by sales, and a salesperson detail table.

**Slicer fields:** calendar year, territory name, territory group, and salesperson name.

The salesperson ranking chart and detail table exclude the synthetic `Online / No Salesperson` member. Active Salespeople counts distinct assigned salesperson IDs in the fact table under current filters. Regional totals may still include unassigned/online sales. Select a single year for the clearest YoY interpretation.

## About This Report

The hidden page describes the AdventureWorks source, star schema, cost methodology, 90-day customer inactivity rule, reporting period, and tools. It has a Back action. The page navigator excludes hidden pages; the information buttons provide navigation to this methodology page.

## Suggested portfolio demonstration

1. Introduce the business questions and establish the unfiltered totals on Executive Overview.
2. Compare Online and Reseller to explain why sales share and estimated margin differ.
3. Move to Customer Analytics and explain the analysis date and 90-day threshold.
4. Use Product Performance to compare revenue leaders with profit leaders.
5. Select a year on Territory & Sales Performance and explain comparable-period growth.
6. Close with the SQL historical-cost lookup, star schema, and documented limitations.

For GitHub previews, export actual pages from Power BI Desktop and add them as images. The repository banner is an editorial project overview, not a rendered report screenshot. Visual layout and interactive behavior still need a Desktop review after a refresh.
