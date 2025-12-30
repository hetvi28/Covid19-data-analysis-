# Covid19-data-analysis-
Analyzed global COVID-19 cases, deaths, and vaccination data using MySQL. Cleaned and standardized large datasets, converted date formats, and handled missing values. Calculated infection, mortality, and vaccination rates using aggregations and window functions, and created reusable views for population level insights.


Perfect — here is a **clean, minimal README.md** with **no code explanation**, just **what the project does and how it was approached**, suitable for GitHub.

---

# COVID-19 Data Analysis (SQL)

## Project Summary

This project analyzes global COVID-19 deaths and vaccination data using MySQL. The workflow focuses on cleaning raw datasets, standardizing formats, and performing analytical queries to understand infection rates, mortality trends, and vaccination progress across countries and continents.

---

## What Was Done

* Cleaned and standardized COVID-19 deaths and vaccination datasets
* Converted text-based date fields into proper DATE format
* Fixed data types for numeric analysis
* Filtered valid country-level records
* Performed country, continent, and global-level aggregations
* Calculated infection, death, and vaccination percentages
* Generated rolling vaccination totals
* Created temporary tables and views for reusable analysis

---

## How It Was Done

* MySQL used for all data cleaning and analysis
* SQL window functions for cumulative metrics
* Joins to combine deaths and vaccination data
* Aggregations for trend and comparative analysis
* Views created to simplify downstream queries

---

## Tools Used

* MySQL
* SQL (DDL, DML, Window Functions)

---

## Output

* Country-level COVID impact metrics
* Continent and global trend summaries
* Population-adjusted infection and vaccination insights

