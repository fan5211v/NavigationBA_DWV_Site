-- Q2.1
WITH
Purchases_Quarter AS (
    SELECT 
        POI.Material_Code,
        SUM(POI.Receive_Quantity)                                         AS Total_Quantity,
        SUM(POI.Receive_Quantity * POI.Price) / SUM(POI.Receive_Quantity) AS Weighted_Average_Cost
    FROM Purchase_Order_Items AS POI
    JOIN Purchase_Orders      AS PO ON POI.Document_Number = PO.Document_Number
    WHERE PO.Delivery_Date >= DATEADD(WEEK, -13, DATETRUNC(WEEK, CURRENT_TIMESTAMP))
    AND   PO.Delivery_Date <  DATETRUNC(WEEK, CURRENT_TIMESTAMP)
    GROUP BY POI.Material_Code
)
SELECT 
    M.Material_Code,
    M.Material_Name,
    M.Unit_Size,
    COALESCE(PQ.Total_Quantity, 0) AS Total_Quantity,
    PQ.Weighted_Average_Cost
FROM Materials              AS M
LEFT JOIN Purchases_Quarter AS PQ ON M.Material_Code = PQ.Material_Code
WHERE M.Type_Code = 'ROH'
ORDER BY M.Material_Code
;

-- Q2.2
WITH
Account_Categories AS (
    SELECT
        Account_Number,
        Account_Name,
        CASE
            WHEN Account_Number IN ('0000211120', '0000211130')                                        THEN 'Depreciation'
            WHEN Account_Number IN ('0000400000', '0000500000', '0000510000')                          THEN 'Manufacturing'
            WHEN Account_Number IN ('0000472000', '0000478100')                                        THEN 'Logistics'
            WHEN Account_Number =   '0000476900'                                                       THEN 'Financing'
            WHEN Account_Number BETWEEN '0000477001' AND '0000477036' OR Account_Number = '0000520000' THEN 'Sales and Administration'
            WHEN Account_Number =   '0000478000'                                                       THEN 'Consulting'
            ELSE                                                                                            'Other'
        END AS Account_Category
    FROM GL_Accounts
    WHERE Account_Group = 'IS-Expenses'
),
Account_Expenditure AS (
    SELECT
        GLA.Account_Number,
        GLP.Posting_Date,
        CASE
            WHEN GLPE.DR_or_CR = 'DR' THEN  GLPE.Amount
            ELSE                           -GLPE.Amount
        END AS Amount
    FROM GL_Accounts        AS GLA
    JOIN GL_Posting_Entries AS GLPE ON GLA.Account_Number   = GLPE.Account_Number
    JOIN GL_Postings        AS GLP  ON GLPE.Document_Number = GLP.Document_Number
    WHERE GLA.Account_Group = 'IS-Expenses'
)
SELECT
    AC.Account_Category,
    COALESCE(SUM(CASE WHEN AE.Posting_Date >= DATETRUNC(YEAR,  CURRENT_TIMESTAMP) THEN AE.Amount ELSE 0 END), 0) AS Year_to_Date,
    COALESCE(SUM(CASE WHEN AE.Posting_Date >= DATETRUNC(MONTH, CURRENT_TIMESTAMP) THEN AE.Amount ELSE 0 END), 0) AS Month_to_Date
FROM Account_Categories       AS AC
LEFT JOIN Account_Expenditure AS AE ON AC.Account_Number = AE.Account_Number
GROUP BY AC.Account_Category
ORDER BY AC.Account_Category
;

-- 或者这样写：

WITH
Account_Categories AS (
    SELECT
        Account_Number,
        Account_Name,
        CASE
            WHEN Account_Number IN ('0000211120', '0000211130')                                        THEN 'Depreciation'
            WHEN Account_Number IN ('0000400000', '0000500000', '0000510000')                          THEN 'Manufacturing'
            WHEN Account_Number IN ('0000472000', '0000478100')                                        THEN 'Logistics'
            WHEN Account_Number =   '0000476900'                                                       THEN 'Financing'
            WHEN Account_Number BETWEEN '0000477001' AND '0000477036' OR Account_Number = '0000520000' THEN 'Sales and Administration'
            WHEN Account_Number =   '0000478000'                                                       THEN 'Consulting'
            ELSE                                                                                            'Other'
        END AS Account_Category
    FROM GL_Accounts
    WHERE Account_Group = 'IS-Expenses'
),
Account_Expenditure AS (
    SELECT
        GLA.Account_Number,
        GLP.Posting_Date,
        CASE
            WHEN GLPE.DR_or_CR = 'DR' THEN  GLPE.Amount
            ELSE                           -GLPE.Amount
        END AS Amount
    FROM GL_Accounts        AS GLA
    JOIN GL_Posting_Entries AS GLPE ON GLA.Account_Number   = GLPE.Account_Number
    JOIN GL_Postings        AS GLP  ON GLPE.Document_Number = GLP.Document_Number
    WHERE GLA.Account_Group = 'IS-Expenses'
),
Account_Expenditure_Time AS (
    SELECT
        Account_Number,
        Posting_Date,
        Amount,
        CASE
            WHEN Posting_Date >= DATETRUNC(YEAR,  CURRENT_TIMESTAMP) THEN Amount
            ELSE 0
        END AS Amount_Year_to_Date,
        CASE
            WHEN Posting_Date >= DATETRUNC(MONTH, CURRENT_TIMESTAMP) THEN Amount
            ELSE 0
        END AS Amount_Month_to_Date
    FROM Account_Expenditure
)
SELECT
    AC.Account_Category,
    COALESCE(SUM(AET.Amount_Year_to_Date), 0) AS Year_to_Date,
    COALESCE(SUM(AET.Amount_Month_to_Date), 0) AS Month_to_Date
FROM Account_Categories            AS AC
LEFT JOIN Account_Expenditure_Time AS AET ON AC.Account_Number = AET.Account_Number
GROUP BY AC.Account_Category
ORDER BY AC.Account_Category
;

-- Q2.3
WITH
Latest_Dates AS (
    SELECT
        Location_Code,
        MAX(Inventory_Date) AS Latest_Date
    FROM Inventory_Counts
    GROUP BY Location_Code
)
SELECT
    M.Material_Code,
    M.Material_Name,
    SUM(IC.Closing_Quantity) AS Available_Inventory
FROM Materials        AS M
JOIN Inventory_Counts AS IC ON M.Material_Code  = IC.Material_Code
JOIN Latest_Dates     AS LD ON IC.Location_Code = LD.Location_Code
WHERE IC.Inventory_Date = LD.Latest_Date
AND   M.Type_Code = 'FERT'
GROUP BY M.Material_Code, M.Material_Name
ORDER BY M.Material_Code
;

-- 如果不要那些我们不生产的产品，具体要不要展示呢，去问Lecturer或Tutor
WITH
Latest_Dates AS (
    SELECT
        Location_Code,
        MAX(Inventory_Date) AS Latest_Date
    FROM Inventory_Counts
    GROUP BY Location_Code
)
SELECT
    M.Material_Code,
    M.Material_Name,
    SUM(IC.Closing_Quantity) AS Available_Inventory
FROM Materials        AS M
JOIN Inventory_Counts AS IC ON M.Material_Code  = IC.Material_Code
JOIN Latest_Dates     AS LD ON IC.Location_Code = LD.Location_Code
WHERE IC.Inventory_Date = LD.Latest_Date
AND   M.Type_Code = 'FERT'
AND   M.Material_Code IN (SELECT DISTINCT Material_Code FROM Production_Orders)
GROUP BY M.Material_Code, M.Material_Name
ORDER BY M.Material_Code
;


-- Q2.4
WITH
Sales_Data AS (
    SELECT
        DATETRUNC(WEEK, Delivery_Date) AS Week_Start_Date,
        M.Material_Code,
        M.Material_Name,
        SOI.Quantity,
        SOI.Price
    FROM Materials         AS M
    JOIN Sales_Order_Items AS SOI ON M.Material_Code = SOI.Material_Code
    JOIN Sales_Orders      AS SO  ON SOI.Document_Number = SO.Document_Number
)
SELECT
    Week_Start_Date,
    Material_Code,
    Material_Name,
    SUM(Quantity) AS Units_Sold,
    SUM(Quantity * Price) AS Revenue
FROM Sales_Data
WHERE Week_Start_Date < DATETRUNC(WEEK, CURRENT_TIMESTAMP) -- Exclude current week
GROUP BY Week_Start_Date, Material_Code, Material_Name
ORDER BY Week_Start_Date DESC, Units_Sold DESC
;

-- Q2.5
WITH
Production_Remaining AS (
    SELECT
        PO.Document_Number,
        M.Material_Code,
        M.Material_Name,
        PO.Scheduled_Start,
        PO.Scheduled_End,
        PO.Planned_Quantity,
        PO.Planned_Quantity - COALESCE(SUM(PY.Yield), 0) AS Remaining_Quantity
    FROM      Production_Orders AS PO
    JOIN      Materials         AS M  ON PO.Material_Code   = M.Material_Code
    LEFT JOIN Production_Yields AS PY ON PO.Document_Number = PY.Document_Number
    GROUP BY PO.Document_Number, M.Material_Code, M.Material_Name, PO.Scheduled_Start, PO.Scheduled_End, PO.Planned_Quantity 
)
SELECT
    *,
    Planned_Quantity - Remaining_Quantity AS Produced_Quantity
FROM Production_Remaining
WHERE Remaining_Quantity > 0
ORDER BY Scheduled_Start
;