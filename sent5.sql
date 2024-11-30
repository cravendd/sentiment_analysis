-- CTE to identify and tag duplicate records based on customer, product, visit date, stage, and action
WITH DuplicateRecords AS (
    SELECT 
        JourneyID,
        CustomerID,
        ProductID,
        VisitDate,
        Stage,
        Action,
        Duration,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action
            ORDER BY JourneyID
        ) AS row_num
    FROM 
        dbo.customer_journey
)

-- Select all records from the CTE (useful for debugging or identifying duplicates)
SELECT *
FROM DuplicateRecords
ORDER BY JourneyID

-- Select the cleaned data, removing duplicates and replacing missing durations with the average for the date
SELECT 
    JourneyID, 
    CustomerID,  
    ProductID,  
    VisitDate,  
    UPPER(Stage) AS Stage,  
    Action,  
    COALESCE(Duration, avg_duration) AS Duration
FROM 
    (
        -- Subquery to calculate the average duration per visit date and assign row numbers to identify duplicates
        SELECT 
            JourneyID,
            CustomerID,  
            ProductID,  
            VisitDate,  
            UPPER(Stage) AS Stage,
            Action,  
            Duration,
            AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action
                ORDER BY JourneyID
            ) AS row_num
        FROM 
            dbo.customer_journey
    ) AS subquery
WHERE 
    row_num = 1;  -- Only select the first occurrence of each duplicate group
