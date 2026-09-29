# ecommerce-customer-churn-sql
A SQL data analysis project focused on cleaning customer churn data, creating derived metrics, and running exploratory business queries in MySQL.

# E-Commerce Customer Churn Analysis (SQL)

Welcome to another SQL data analysis project in my repository! In this project, I used **MySQL Workbench** to work with an e-commerce customer dataset. I cleaned missing and inconsistent values, created derived metrics for better reporting, and answered business queries related to customer churn and returns.

---

## 📁 Repository Structure

* `E-Commerce Customer churn db` - The original database schema and dataset (INSERT statements).
* `ecom_churn_analysis.sql` - Complete SQL script containing data cleaning, transformation, and analytical queries.
* `README.md` - Project summary and instructions.

---

## 🛠️ Tools & Technologies
* **Database Management System:** MySQL
* **Interface:** MySQL Workbench
* **Language:** SQL (Data Definition, Data Manipulation, and Data Querying)

---

## ⚙️ How to Run This Project

1. **Set Up Database:**
   * Open `E-Commerce Customer churn db` in MySQL Workbench and run the script to create the database (`ecomm`) and populate the `customer_churn` table.

2. **Run Analysis & Cleaning Script:**
   * Open `ecom_churn_analysis.sql` in MySQL Workbench.
   * Run the script to handle missing values, update category labels, execute business analysis queries, and join customer return records.

---

## 📊 Key Highlights & Findings

* **Customer Churn:** Identified churned vs. active customer counts and evaluated their average tenure and cashback totals.
* **Customer Complaints:** Analyzed the proportion of churned customers who submitted complaints prior to churning.
* **Order & Payment Patterns:** Examined payment mode preferences, device usage, and city-tier distributions across product categories.
* **Relational Joins:** Created a secondary `customer_returns` table to track order refunds for churned customers with active complaints.

---

## 👩‍💻 About Me
I am a finance graduate continuously developing my skills in SQL, data cleaning, and business analytics. Check out my other repositories for more projects, and feel free to connect or share suggestions!
