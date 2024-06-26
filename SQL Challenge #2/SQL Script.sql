--@AUTHOR Jasmine Abtahi

--CREATE THE TABLES
CREATE TABLE BATCH (
	BATCH_ID VARCHAR(10) NOT NULL PRIMARY KEY,
	QUANTITY INT
);

CREATE TABLE ORDERS (
	ORDER_NUMBER VARCHAR(10) NOT NULL PRIMARY KEY,
	QUANTITY INT
);

--DESCRIBE TABLE (SHOW METADATA)
EXEC sp_help BATCH;
EXEC sp_help ORDERS;

--INSERT VALUES
INSERT INTO BATCH VALUES ('B1', 5);
INSERT INTO BATCH VALUES ('B2', 12);
INSERT INTO BATCH VALUES ('B3', 8);
-----------------------------------
INSERT INTO ORDERS VALUES ('O1', 2);
INSERT INTO ORDERS VALUES ('O2', 8);
INSERT INTO ORDERS VALUES ('O3', 2);
INSERT INTO ORDERS VALUES ('O4', 5);
INSERT INTO ORDERS VALUES ('O5', 9);
INSERT INTO ORDERS VALUES ('O6', 5);

--FETCH
SELECT * 
FROM BATCH;

SELECT *
FROM ORDERS;

-- EXPANDING THE BATCH TABLE WITH 1'S USING CTE (COMMON TABLE EXPRESSION)
WITH BATCH_CTE AS
    (SELECT BATCH_ID, 1 AS QUANTITY -- BASE 
    FROM BATCH
    UNION ALL
    SELECT BATCH_CTE.BATCH_ID, BATCH_CTE.QUANTITY + 1 -- RECURSION 
    FROM BATCH_CTE
    JOIN BATCH ON BATCH.BATCH_ID = BATCH_CTE.BATCH_ID AND BATCH_CTE.QUANTITY + 1 <= BATCH.QUANTITY),

    BATCH_ONES AS
    (SELECT ROW_NUMBER() OVER(ORDER BY BATCH_ID) AS ROW_NUMBER, BATCH_ID, 1 AS QUANTITY
    FROM BATCH_CTE),

-- EXPANDING THE ORDERS TABLE WITH 1'S USING CTE (COMMON TABLE EXPRESSION)
    ORDERS_CTE AS 
    (SELECT ORDER_NUMBER, 1 AS QUANTITY -- BASE 
    FROM ORDERS
    UNION ALL
    SELECT ORDERS_CTE.ORDER_NUMBER, ORDERS_CTE.QUANTITY + 1 -- RECURSION 
    FROM ORDERS_CTE
    JOIN ORDERS ON ORDERS.ORDER_NUMBER = ORDERS_CTE.ORDER_NUMBER AND ORDERS_CTE.QUANTITY + 1 <= ORDERS.QUANTITY),

    ORDERS_ONES AS
    (SELECT ROW_NUMBER() OVER(ORDER BY ORDER_NUMBER) AS ROW_NUMBER, ORDER_NUMBER, 1 AS QUANTITY
    FROM ORDERS_CTE),

--OUTPUT 
    RESULT AS
    (SELECT ORDER_NUMBER, BATCH_ID, COUNT(BATCH_ONES.QUANTITY) AS QUANTITY
    FROM BATCH_ONES
    LEFT JOIN ORDERS_ONES ON ORDERS_ONES.ROW_NUMBER = BATCH_ONES.ROW_NUMBER
    GROUP BY ORDER_NUMBER, BATCH_ID)

SELECT * 
FROM RESULT;


-- DROP TABLE BATCH;
-- DROP TABLE ORDERS;

