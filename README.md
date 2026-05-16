# E-commerce Sales Analytics Dashboard

Sales analytics dashboard for an online retail business based on the Online Retail dataset.

The project covers the full data workflow: data cleaning in Python, metric calculation in PostgreSQL, and dashboard development in Qlik Cloud.

## Tools

Python, Pandas, PostgreSQL, SQL, Qlik Cloud, OpenAI API

## Workflow

1. Cleaned raw transactional data in Python:
   - handled returns and cancelled invoices;
   - removed invalid and non-product records;
   - created revenue, return flag, and monthly period fields;
   - grouped product descriptions into broader categories using NLP-assisted categorization.

2. Built SQL views in PostgreSQL for:
   - revenue and orders;
   - active customers;
   - average order value;
   - monthly sales trends;
   - customer segments;
   - product and category analysis.

3. Created an interactive dashboard in Qlik Cloud for:
   - KPI overview;
   - sales trends;
   - category analysis;
   - top products;
   - customer analysis.

## Repository Structure

```text
notebooks/     Python data cleaning and categorization
sql/           SQL scripts and analytical views
dashboard/     Qlik dashboard file
screenshots/   Dashboard screenshots
