# 📊 Omair Sales — Data Analysis Projects

End-to-end data analysis across **Excel, Power BI, Python, and SQL Server** on a Saudi retail dataset (1,998 transactions, 2004–2006).

**Author:** Hussam Ali — [@hossamoov](https://github.com/hossamoov)  
**Instructor**: Dr. Abdullah Al-Omair

---

## 📁 Repository Structure

```
├── projects/
│   ├── 01_excel/      excel_project.xlsx
│   ├── 02_powerbi/    powerbi_report.pbix
│   ├── 03_python/     python_analysis.ipynb
│   └── 04_sql/        sql_bonus.sql + results
└── data/
    └── OmairSalesDataProject.xlsx (original unclean)
```

---

## 📊 Key Metrics

| Metric | Value |
|---|---|
| Total Sales | **10,075,360.98 SAR** |
| Total Profit | **3,796,445.84 SAR** |
| Profit Margin | **37.68%** |
| Transactions | 1,998 |

> All four tools produce identical numerical results — cross-validated.

---

## 🧬 Cleaning Methodology

Same logic implemented in **Power Query (M)**, **Python (pandas)**, and **SQL Server (T-SQL)**:

1. **IQR-based outlier detection** — bounds = `[Q1 − 1.5·IQR, Q3 + 1.5·IQR]`
2. **Ratio imputation** — replace problematic Cost with `Sale × Ratio` (preserves variance)
3. **CostFlag audit column** — records every imputation (OK / Missing / Zero / Outlier)
4. **Date repair** — Year > 2010 → subtract 10 years
5. **Typo fixes** — `Mjeeed → Mjeed`, `Lulu Hyper → Lulu`

---

## 🚀 Quick Start

```bash
git clone https://github.com/hossamoov/HussamAli_DataAnalysis.git
cd HussamAli_DataAnalysis
```

- **Excel**: open `projects/01_excel/excel_project.xlsx`
- **Power BI**: open `projects/02_powerbi/powerbi_report.pbix`
- **Python**: `jupyter notebook projects/03_python/python_analysis.ipynb`
- **SQL**: import `data/OmairSalesDataProject.xlsx` into SQL Server, run `projects/04_sql/sql_bonus.sql`

---

## 🔍 Key Findings

- **Geographic balance** — only 30% spread between top (Riyadh: 715K) and bottom (Hail: 552K) profit
- **Product portfolio** — margins clustered at 37–38% across all categories (low concentration risk)
- **Top reps per category**: Food/Toys/Home → Ghalia · Office → Yahia
- **Data quality** — caught 1 extreme outlier (50M Cost), 3 date errors, 2 typo variants
