USE [SalesData];
GO
/* ---------------------------------------------------------------------
   Q1 (EASY) — Total sales by city
   ---------------------------------------------------------------------
   For each city, return TotalSales and TotalProfit, 
   sorted by total profit (highest first).
   --------------------------------------------------------------------- */
WITH 
Bounds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER () AS Q3,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()
          - 1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
                 - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()) AS LowerBound,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
          + 1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
                 - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()) AS UpperBound
    FROM [dbo].[SalesData]
    WHERE Cost IS NOT NULL
),
RatioCalc AS (
    SELECT SUM(s.Cost) / NULLIF(SUM(s.Sale), 0) AS Ratio
    FROM [dbo].[SalesData] s
    CROSS JOIN Bounds b
    WHERE s.Cost IS NOT NULL AND s.Cost <> 0
      AND s.Cost >= b.LowerBound AND s.Cost <= b.UpperBound
      AND s.Sale IS NOT NULL AND s.Sale > 0
),
Cleaned AS (
    SELECT
        UPPER(LEFT(LTRIM(RTRIM(s.City)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(s.City)),2,50)) AS City,
        CASE
            WHEN s.Cost IS NULL OR s.Cost = 0 
              OR s.Cost < b.LowerBound OR s.Cost > b.UpperBound
                THEN ROUND(s.Sale * r.Ratio, 2)
            ELSE ROUND(s.Cost, 2)
        END AS Cost,
        ROUND(s.Sale, 2) AS Sale
    FROM [dbo].[SalesData] s
    CROSS JOIN Bounds b
    CROSS JOIN RatioCalc r
)
SELECT
    City,
    CAST(SUM(Sale)        AS DECIMAL(14,2)) AS TotalSales,
    CAST(SUM(Sale - Cost) AS DECIMAL(14,2)) AS TotalProfit
FROM Cleaned
GROUP BY City
ORDER BY TotalProfit DESC;

/*  results :
   
City	TotalSales	TotalProfit
Riyadh	1797653.68	715437.01
Dammam	1880961.32	693667.36
Jeddah	1708310.19	623122.77
Jubail	1562105.63	613097.33
Abha	1644938.73	598674.79
Hail	1481391.43	552446.44
*/

GO



/* ---------------------------------------------------------------------
   Q2 (INTERMEDIATE) — Top sales rep per product category
   ---------------------------------------------------------------------
   For each Prod, find the Rep with the highest total profit.
   Return one row per product category.
   --------------------------------------------------------------------- */

WITH 
Bounds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER () AS Q3,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()
          - 1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
                 - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()) AS LowerBound,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
          + 1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
                 - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()) AS UpperBound
    FROM [dbo].[SalesData]
    WHERE Cost IS NOT NULL
),
RatioCalc AS (
    SELECT SUM(s.Cost) / NULLIF(SUM(s.Sale), 0) AS Ratio
    FROM [dbo].[SalesData] s
    CROSS JOIN Bounds b
    WHERE s.Cost IS NOT NULL AND s.Cost <> 0
      AND s.Cost >= b.LowerBound AND s.Cost <= b.UpperBound
      AND s.Sale IS NOT NULL AND s.Sale > 0
),
Cleaned AS (
    SELECT
        UPPER(LEFT(LTRIM(RTRIM(s.Prod)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(s.Prod)),2,50)) AS Prod,
        CASE 
            WHEN LTRIM(RTRIM(s.Rep)) = 'Mjeeed' THEN 'Mjeed'
            ELSE UPPER(LEFT(LTRIM(RTRIM(s.Rep)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(s.Rep)),2,50))
        END AS Rep,
        CASE
            WHEN s.Cost IS NULL OR s.Cost = 0 
              OR s.Cost < b.LowerBound OR s.Cost > b.UpperBound
                THEN ROUND(s.Sale * r.Ratio, 2)
            ELSE ROUND(s.Cost, 2)
        END AS Cost,
        ROUND(s.Sale, 2) AS Sale
    FROM [dbo].[SalesData] s
    CROSS JOIN Bounds b
    CROSS JOIN RatioCalc r
),
RepProfitPerProd AS (
    SELECT
        Prod,
        Rep,
        CAST(SUM(Sale - Cost) AS DECIMAL(14,2)) AS TotalProfit,
        ROW_NUMBER() OVER (
            PARTITION BY Prod 
            ORDER BY SUM(Sale - Cost) DESC
        ) AS rn
    FROM Cleaned
    GROUP BY Prod, Rep
)
SELECT
    Prod,
    Rep,
    TotalProfit
FROM RepProfitPerProd
WHERE rn = 1
ORDER BY Prod;

/*  results:
   
Prod	Rep	TotalProfit
Food	Ghalia	230868.13
Home	Maliha	184763.39
Office	Yahia	249543.00
Toys	Ghalia	226749.22

*/

GO



/* ---------------------------------------------------------------------
   Q3 (HARD) — Month-over-month profit growth per city
   ---------------------------------------------------------------------
   For each (City, Month), return MonthlyProfit and the % change vs 
   the previous month for that same city. Show only rows where the 
   previous month exists.
   --------------------------------------------------------------------- */

WITH 
Bounds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER () AS Q3,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()
          - 1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
                 - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()) AS LowerBound,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
          + 1.5 * (PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Cost) OVER ()
                 - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Cost) OVER ()) AS UpperBound
    FROM [dbo].[SalesData]
    WHERE Cost IS NOT NULL
),
RatioCalc AS (
    SELECT SUM(s.Cost) / NULLIF(SUM(s.Sale), 0) AS Ratio
    FROM [dbo].[SalesData] s
    CROSS JOIN Bounds b
    WHERE s.Cost IS NOT NULL AND s.Cost <> 0
      AND s.Cost >= b.LowerBound AND s.Cost <= b.UpperBound
      AND s.Sale IS NOT NULL AND s.Sale > 0
),
Cleaned AS (
    SELECT
        CASE 
            WHEN YEAR(s.Date) > 2010 THEN DATEADD(YEAR, -10, s.Date)
            ELSE s.Date
        END AS Date,
        UPPER(LEFT(LTRIM(RTRIM(s.City)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(s.City)),2,50)) AS City,
        CASE
            WHEN s.Cost IS NULL OR s.Cost = 0 
              OR s.Cost < b.LowerBound OR s.Cost > b.UpperBound
                THEN ROUND(s.Sale * r.Ratio, 2)
            ELSE ROUND(s.Cost, 2)
        END AS Cost,
        ROUND(s.Sale, 2) AS Sale
    FROM [dbo].[SalesData] s
    CROSS JOIN Bounds b
    CROSS JOIN RatioCalc r
),
MonthlyCity AS (
    SELECT
        City,
        DATEFROMPARTS(YEAR(Date), MONTH(Date), 1)  AS YearMonth,
        CAST(SUM(Sale - Cost) AS DECIMAL(14,2))    AS MonthlyProfit
    FROM Cleaned
    GROUP BY 
        City,
        DATEFROMPARTS(YEAR(Date), MONTH(Date), 1)
),
WithLag AS (
    SELECT
        City,
        YearMonth,
        MonthlyProfit,
        LAG(MonthlyProfit) OVER (
            PARTITION BY City 
            ORDER BY YearMonth
        ) AS PrevMonthProfit
    FROM MonthlyCity
)
SELECT
    City,
    YearMonth,
    MonthlyProfit,
    PrevMonthProfit,
    CAST(
        100.0 * (MonthlyProfit - PrevMonthProfit) 
        / NULLIF(PrevMonthProfit, 0)
    AS DECIMAL(8,2)) AS MoMGrowthPct
FROM WithLag
WHERE PrevMonthProfit IS NOT NULL
ORDER BY City, YearMonth;

/* results:
   
City	YearMonth	MonthlyProfit	PrevMonthProfit	MoMGrowthPct
Abha	2004-07-01	15099.72	11678.37	29.30
Abha	2004-08-01	26449.46	15099.72	75.17
Abha	2004-09-01	44262.75	26449.46	67.35
Abha	2004-10-01	36011.07	44262.75	-18.64
Abha	2004-11-01	28578.10	36011.07	-20.64
Abha	2004-12-01	21153.69	28578.10	-25.98
Abha	2005-01-01	16997.82	21153.69	-19.65
Abha	2005-02-01	41393.48	16997.82	143.52
Abha	2005-03-01	35941.80	41393.48	-13.17
Abha	2005-04-01	11813.83	35941.80	-67.13
Abha	2005-05-01	33913.77	11813.83	187.07
Abha	2005-06-01	8908.60	    33913.77	-73.73
Abha	2005-07-01	36855.24	8908.60	    313.70
Abha	2005-08-01	20461.78	36855.24	-44.48
Abha	2005-09-01	16573.51	20461.78	-19.00
Abha	2005-10-01	23882.49	16573.51	44.10
Abha	2005-11-01	20526.46	23882.49	-14.05
Abha	2005-12-01	22859.65	20526.46	11.37
Abha	2006-01-01	20912.57	22859.65	-8.52
Abha	2006-02-01	14116.17	20912.57	-32.50
Abha	2006-03-01	24860.46	14116.17	76.11
Abha	2006-04-01	19083.92	24860.46	-23.24
Abha	2006-05-01	36770.01	19083.92	92.68
Abha	2006-06-01	9570.07	    36770.01	-73.97
Dammam	2004-07-01	42433.58	13243.50	220.41
Dammam	2004-08-01	32552.00	42433.58	-23.29
Dammam	2004-09-01	20793.47	32552.00	-36.12
Dammam	2004-10-01	14151.96	20793.47	-31.94
Dammam	2004-11-01	25820.70	14151.96	82.45
Dammam	2004-12-01	45033.15	25820.70	74.41
Dammam	2005-01-01	41775.92	45033.15	-7.23
Dammam	2005-02-01	32662.63	41775.92	-21.81
Dammam	2005-03-01	23856.25	32662.63	-26.96
Dammam	2005-04-01	19654.53	23856.25	-17.61
Dammam	2005-05-01	41998.13	19654.53	113.68
Dammam	2005-06-01	40179.20	41998.13	-4.33
Dammam	2005-07-01	35565.04	40179.20	-11.48
Dammam	2005-08-01	10721.49	35565.04	-69.85
Dammam	2005-09-01	28392.79	10721.49	164.82
Dammam	2005-10-01	35609.23	28392.79	25.42
Dammam	2005-11-01	20760.56	35609.23	-41.70
Dammam	2005-12-01	30641.63	20760.56	47.60
Dammam	2006-01-01	24563.65	30641.63	-19.84
Dammam	2006-02-01	30015.38	24563.65	22.19
Dammam	2006-03-01	16238.72	30015.38	-45.90
Dammam	2006-04-01	10613.47	16238.72	-34.64
Dammam	2006-05-01	38491.65	10613.47	262.67
Dammam	2006-06-01	17898.73	38491.65	-53.50
Hail	2004-07-01	14291.15	15472.24	-7.63
Hail	2004-08-01	25560.71	14291.15	78.86
Hail	2004-09-01	28480.31	25560.71	11.42
Hail	2004-10-01	24751.32	28480.31	-13.09
Hail	2004-11-01	19477.92	24751.32	-21.31
Hail	2004-12-01	24948.84	19477.92	28.09
Hail	2005-01-01	31041.62	24948.84	24.42
Hail	2005-02-01	3696.93	    31041.62	-88.09
Hail	2005-03-01	42876.93	3696.93	    1059.80
Hail	2005-04-01	24660.71	42876.93	-42.48
Hail	2005-05-01	11718.45	24660.71	-52.48
Hail	2005-06-01	22582.49	11718.45	92.71
Hail	2005-07-01	34464.81	22582.49	52.62
Hail	2005-08-01	15872.20	34464.81	-53.95
Hail	2005-09-01	29116.95	15872.20	83.45
Hail	2005-10-01	15689.25	29116.95	-46.12
Hail	2005-11-01	33752.78	15689.25	115.13
Hail	2005-12-01	29234.89	33752.78	-13.39
Hail	2006-01-01	15381.98	29234.89	-47.38
Hail	2006-02-01	20183.48	15381.98	31.22
Hail	2006-03-01	28009.76	20183.48	38.78
Hail	2006-04-01	11158.35	28009.76	-60.16
Hail	2006-05-01	19050.59	11158.35	70.73
Hail	2006-06-01	10971.78	19050.59	-42.41
Jeddah	2004-07-01	30957.87	7980.13	    287.94
Jeddah	2004-08-01	24516.92	30957.87	-20.81
Jeddah	2004-09-01	26549.01	24516.92	8.29
Jeddah	2004-10-01	25302.32	26549.01	-4.70
Jeddah	2004-11-01	16622.97	25302.32	-34.30
Jeddah	2004-12-01	26920.75	16622.97	61.95
Jeddah	2005-01-01	40167.70	26920.75	49.21
Jeddah	2005-02-01	18574.24	40167.70	-53.76
Jeddah	2005-03-01	21149.49	18574.24	13.86
Jeddah	2005-04-01	19925.78	21149.49	-5.79
Jeddah	2005-05-01	11676.15	19925.78	-41.40
Jeddah	2005-06-01	30594.30	11676.15	162.02
Jeddah	2005-07-01	29203.60	30594.30	-4.55
Jeddah	2005-08-01	26045.08	29203.60	-10.82
Jeddah	2005-09-01	42509.57	26045.08	63.22
Jeddah	2005-10-01	24940.43	42509.57	-41.33
Jeddah	2005-11-01	23575.36	24940.43	-5.47
Jeddah	2005-12-01	30070.98	23575.36	27.55
Jeddah	2006-01-01	24661.53	30070.98	-17.99
Jeddah	2006-02-01	27952.73	24661.53	13.35
Jeddah	2006-03-01	36336.18	27952.73	29.99
Jeddah	2006-04-01	10977.58	36336.18	-69.79
Jeddah	2006-05-01	37381.16	10977.58	240.52
Jeddah	2006-06-01	8530.94	    37381.16	-77.18
Jubail	2004-07-01	26629.57	15712.32	69.48
Jubail	2004-08-01	22537.70	26629.57	-15.37
Jubail	2004-09-01	37591.91	22537.70	66.80
Jubail	2004-10-01	25009.45	37591.91	-33.47
Jubail	2004-11-01	2059.94	    25009.45	-91.76
Jubail	2004-12-01	30573.88	2059.94	    1384.21
Jubail	2005-01-01	31005.79	30573.88	1.41
Jubail	2005-02-01	20025.79	31005.79	-35.41
Jubail	2005-03-01	10013.84	20025.79	-50.00
Jubail	2005-04-01	23054.62	10013.84	130.23
Jubail	2005-05-01	28677.66	23054.62	24.39
Jubail	2005-06-01	24213.61	28677.66	-15.57
Jubail	2005-07-01	14109.43	24213.61	-41.73
Jubail	2005-08-01	37548.01	14109.43	166.12
Jubail	2005-09-01	20339.70	37548.01	-45.83
Jubail	2005-10-01	29872.74	20339.70	46.87
Jubail	2005-11-01	8934.95	    29872.74	-70.09
Jubail	2005-12-01	30570.49	8934.95	    242.15
Jubail	2006-01-01	28113.23	30570.49	-8.04
Jubail	2006-02-01	11753.91	28113.23	-58.19
Jubail	2006-03-01	21592.60	11753.91	83.71
Jubail	2006-04-01	41083.96	21592.60	90.27
Jubail	2006-05-01	46957.65	41083.96	14.30
Jubail	2006-06-01	25114.58	46957.65	-46.52
Riyadh	2004-07-01	34012.60	13582.81	150.41
Riyadh	2004-08-01	34595.34	34012.60	1.71
Riyadh	2004-09-01	22334.33	34595.34	-35.44
Riyadh	2004-10-01	22932.89	22334.33	2.68
Riyadh	2004-11-01	24864.67	22932.89	8.42
Riyadh	2004-12-01	44680.88	24864.67	79.70
Riyadh	2005-01-01	32574.71	44680.88	-27.09
Riyadh	2005-02-01	19915.89	32574.71	-38.86
Riyadh	2005-03-01	29673.85	19915.89	49.00
Riyadh	2005-04-01	21845.46	29673.85	-26.38
Riyadh	2005-05-01	35335.51	21845.46	61.75
Riyadh	2005-06-01	13455.49	35335.51	-61.92
Riyadh	2005-07-01	40918.23	13455.49	204.10
Riyadh	2005-08-01	37794.43	40918.23	-7.63
Riyadh	2005-09-01	32342.01	37794.43	-14.43
Riyadh	2005-10-01	31553.12	32342.01	-2.44
Riyadh	2005-11-01	32879.33	31553.12	4.20
Riyadh	2005-12-01	32623.25	32879.33	-0.78
Riyadh	2006-01-01	9851.16	    32623.25	-69.80
Riyadh	2006-02-01	25337.89	9851.16	    157.21
Riyadh	2006-03-01	39223.33	25337.89	54.80
Riyadh	2006-04-01	48666.20	39223.33	24.07
Riyadh	2006-05-01	18706.61	48666.20	-61.56
Riyadh	2006-06-01	15737.02	18706.61	-15.87
*/

GO