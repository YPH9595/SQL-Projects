--@AUTHOR Jasmine Abtahi

-- CREATE THE TABLE
CREATE TABLE WAREHOUSE (
	ID VARCHAR(10) NOT NULL PRIMARY KEY,
	OnHandQuantity INT,
	OnHandQuantityDelta INT,
	event_type VARCHAR(10),
	event_datetime DATETIME
);

--DESCRIBE TABLE (SHOW METADATA) 
EXEC sp_help WAREHOUSE;

--INSERT VALUES INTO THE TABLE
INSERT INTO WAREHOUSE VALUES ('SH0013', 278,   99 ,   'OutBound', '2020-05-25 0:25');
INSERT INTO WAREHOUSE VALUES ('SH0012', 377,   31 ,   'InBound', '2020-05-24 22:00');
INSERT INTO WAREHOUSE VALUES ('SH0011', 346,   1  ,   'OutBound', '2020-05-24 15:01');
INSERT INTO WAREHOUSE VALUES ('SH0010', 346,   1  ,   'OutBound', '2020-05-23 5:00');
INSERT INTO WAREHOUSE VALUES ('SH009',  348,   102,   'InBound', '2020-04-25 18:00');
INSERT INTO WAREHOUSE VALUES ('SH008',  246,   43 ,   'InBound', '2020-04-25 2:00');
INSERT INTO WAREHOUSE VALUES ('SH007',  203,   2  ,   'OutBound', '2020-02-25 9:00');
INSERT INTO WAREHOUSE VALUES ('SH006',  205,   129,   'OutBound', '2020-02-18 7:00');
INSERT INTO WAREHOUSE VALUES ('SH005',  334,   1  ,   'OutBound', '2020-02-18 8:00');
INSERT INTO WAREHOUSE VALUES ('SH004',  335,   27 ,   'OutBound', '2020-01-29 5:00');
INSERT INTO WAREHOUSE VALUES ('SH003',  362,   120,   'InBound', '2019-12-31 2:00');
INSERT INTO WAREHOUSE VALUES ('SH002',  242,   8  ,   'OutBound', '2019-05-22 0:50');
INSERT INTO WAREHOUSE VALUES ('SH001',  250,   250,   'InBound', '2019-05-20 0:45');

--FETCH THE TABLE
SELECT * 
FROM WAREHOUSE
ORDER BY event_datetime;

--ADD ROWS UNTIL THE THRESHOLD (OnHandQuantityDelta #) IS MET 
WITH CTE AS (
    SELECT 1 AS QUANTITY, event_datetime, event_type --BASE 
    FROM WAREHOUSE
    UNION ALL --ITERATION
    SELECT CTE.QUANTITY + 1, CTE.event_datetime, CTE.event_type
    FROM CTE
    JOIN WAREHOUSE W 
        ON CTE.event_datetime = W.event_datetime 
       AND CTE.QUANTITY + 1 <= W.OnHandQuantityDelta
),
--ADD 1'S COLUMN AND ROW NUMBER 
RANKED AS (
    SELECT 1 AS QUANTITY, event_datetime, event_type, 
           ROW_NUMBER() OVER (PARTITION BY event_type ORDER BY event_datetime) AS rank
    FROM CTE
),
--CALCULATE REMAINED ITEMS 
REMAINED AS (
    SELECT R1.event_datetime, 
           SUM(R1.QUANTITY - ISNULL(R2.QUANTITY, 0)) AS remained 
    FROM RANKED R1
    LEFT JOIN RANKED R2 
        ON R1.rank = R2.rank 
       AND R1.event_type != R2.event_type
    WHERE R1.event_type = 'Inbound'
    GROUP BY R1.event_datetime
), 
--CRETAE THE 4 PERIOD INTERVALS 
PERIODS AS (
    SELECT remained, 
           CASE 
               WHEN event_datetime < DATEADD(DAY, -365, latest) THEN 0
               WHEN event_datetime < DATEADD(DAY, -270, latest) 
                    AND event_datetime >= DATEADD(DAY, -365, latest) THEN 1
               WHEN event_datetime < DATEADD(DAY, -180, latest) 
                    AND event_datetime >= DATEADD(DAY, -270, latest) THEN 2
               WHEN event_datetime < DATEADD(DAY, -90, latest) 
                    AND event_datetime >= DATEADD(DAY, -180, latest) THEN 3
               ELSE 4
           END AS event_period
    FROM REMAINED 
    CROSS JOIN (
        SELECT MAX(event_datetime) AS latest 
        FROM WAREHOUSE
    ) MAX_DAY 
),
--ADD THE RIGHT COLUMNS FOR OUTPUT 
RESULT AS (
    SELECT SUM(REMAINED) AS total_remained, event_period
    FROM PERIODS 
    GROUP BY event_period
)
--REDUCE THE RESULT TABLE TO ONE ROW 
SELECT MAX(CASE WHEN event_period = 4 THEN total_remained ELSE 0 END) AS '0-90 days old',
       MAX(CASE WHEN event_period = 3 THEN total_remained ELSE 0 END) AS '91-180 days old',
       MAX(CASE WHEN event_period = 2 THEN total_remained ELSE 0 END) AS '181-270 days old',
       MAX(CASE WHEN event_period = 1 THEN total_remained ELSE 0 END) AS '271-365 days old'
FROM RESULT 
OPTION (MAXRECURSION 0); --INFINITE LOOP CTE


--DROP TABLE WAREHOUSE;