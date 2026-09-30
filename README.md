# Zomato Data Analytics Project

Zomato restaurant data analysis using Python, SQL, and Power BI.

## Project Overview

In this project, I analyzed a Zomato restaurant dataset to understand restaurant ratings, cuisines, pricing, votes, cities, countries, and online services.

The project covers data cleaning and analysis in Python, business queries in SQL, and an interactive dashboard in Power BI.

## Project Pipeline
Zomato CSV Dataset
(zomato.csv)
        ↓
Python
(Data Cleaning & Exploration)
[notebook.ipynb]
        ↓
PostgreSQL
(Main Table: public.zomato)
[Zomato_Phase2_SQL_Portfolio.sql]
        ↓
Cuisine Transformation
(Supporting Table: public.restaurant_cuisines)
[cusine.sql]
        ↓
Power BI
(Data Modeling, DAX & Dashboard)
[Zomato_Data_Analyst_Portfolio.pbix]
        ↓
Business Insights

## Tools Used

- Python
- Pandas
- Matplotlib
- PostgreSQL
- SQL
- Power BI
- DAX

## Project Work

### 1. Python

- Loaded and inspected the dataset
- Checked missing values and duplicates
- Handled missing cuisine values
- Mapped country codes to country names
- Created price range and rating categories
- Separated rated and unrated restaurants
- Analyzed cuisines, countries, prices, ratings, votes, delivery, and table booking
- Created charts for business insights

### 2. SQL

Used PostgreSQL to answer business questions such as:

- Restaurants by country
- Average rating and votes by city
- Never-rated restaurants
- Online delivery and table booking vs rating
- Price range vs rating and votes
- Top cuisines
- Best-rated cuisines with a minimum restaurant count
- Top cities by country
- Most-voted restaurants
- Rating distribution
- India city-level analysis

### 3. Power BI

Created a 3-page dashboard:

- Executive Overview
- Market & City Analysis
- Cuisine & Restaurant Analysis

The dashboard includes KPIs, filters, city analysis, cuisine analysis, rating analysis, and restaurant popularity analysis.

## Key Areas Analyzed

- Restaurant ratings
- Restaurant popularity using votes
- Price segments
- Cuisines
- Cities and countries
- Online delivery
- Table booking
- Unrated restaurants

## Files

- `notebook.ipynb` — Python analysis
- `Zomato_Phase2_SQL_Portfolio.sql` — SQL queries
- `cusine.sql` — Cuisine table preparation
- `Zomato_Data_Analyst_Portfolio.pbix` — Power BI dashboard
- `zomato.csv` — Dataset

## Note

This is a learning and portfolio project created to practice data analysis using Python, SQL, and Power BI.
