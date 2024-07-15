--@AUTHOR Jasmine Abtahi

CREATE TABLE Hackers (
    hacker_id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE Submissions (
    submission_date DATE,
    submission_id INT PRIMARY KEY,
    hacker_id INT,
    score INT,
    FOREIGN KEY (hacker_id) REFERENCES Hackers(hacker_id)
);

--INSERT VALUES
INSERT INTO Hackers VALUES (15758, 'Rose');
INSERT INTO Hackers VALUES (20703, 'Angela');
INSERT INTO Hackers VALUES (36396, 'Frank');
INSERT INTO Hackers VALUES (38289, 'Patrick');
INSERT INTO Hackers VALUES (44065, 'Lisa');
INSERT INTO Hackers VALUES (53473, 'Kimberly');
INSERT INTO Hackers VALUES (62529, 'Bonnie');
INSERT INTO Hackers VALUES (79722, 'Michael');
---------------------------------------------------------------------
INSERT INTO Submissions VALUES ('2016-03-01', 8494, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-01', 22403, 53473, 15);
INSERT INTO Submissions VALUES ('2016-03-01', 23965, 79722, 60);
INSERT INTO Submissions VALUES ('2016-03-01', 30173, 36396, 70);
INSERT INTO Submissions VALUES ('2016-03-02', 34928, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-02', 38740, 15758, 60);
INSERT INTO Submissions VALUES ('2016-03-02', 42769, 79722, 25);
INSERT INTO Submissions VALUES ('2016-03-02', 44364, 79722, 60);
INSERT INTO Submissions VALUES ('2016-03-03', 45440, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-03', 49050, 36396, 70);
INSERT INTO Submissions VALUES ('2016-03-03', 50273, 79722, 5);
INSERT INTO Submissions VALUES ('2016-03-04', 50344, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-04', 51360, 44065, 90);
INSERT INTO Submissions VALUES ('2016-03-04', 54404, 53473, 65);
INSERT INTO Submissions VALUES ('2016-03-04', 61533, 79722, 45);
INSERT INTO Submissions VALUES ('2016-03-05', 72852, 20703, 0);
INSERT INTO Submissions VALUES ('2016-03-05', 74546, 38289, 0);
INSERT INTO Submissions VALUES ('2016-03-05', 76487, 62529, 0);
INSERT INTO Submissions VALUES ('2016-03-05', 82439, 36396, 10);
INSERT INTO Submissions VALUES ('2016-03-05', 90006, 36396, 40);
INSERT INTO Submissions VALUES ('2016-03-06', 90404, 20703, 0);

--FETCH
SELECT *
FROM Hackers;

SELECT *
FROM Submissions;

-- List unique hackers who made at least 1 submission each day (starting on the first day of the contest)

WITH CTE AS (
    -- BASE: made of the first date entries in Submission table 
    SELECT S.submission_date, hacker_id 
    FROM Submissions S, (
        SELECT TOP 1 submission_date 
        FROM Submissions
        GROUP BY submission_date
        ORDER BY submission_date
    ) TOP_ONE -- the first date  
    WHERE S.submission_date = TOP_ONE.submission_date

    UNION ALL 
    
    -- Recursive part of the CTE
    SELECT S.submission_date, S.hacker_id 
    FROM CTE
    JOIN Submissions S 
        ON DATEADD(DAY, +1, CTE.submission_date) = S.submission_date 
        AND CTE.hacker_id = S.hacker_id
),

-- Count unique hackers per day
UNIQUE_HACKERS_PER_DAY AS (
    SELECT submission_date, COUNT(DISTINCT hacker_id) AS unique_hackers_count
    FROM CTE
    GROUP BY submission_date
),

-- Ordered list of hackers based on number of submissions, for each day
MAX_SUBMISSIONS AS (
    SELECT ROW_NUMBER() OVER (ORDER BY submission_date, COUNT(*) DESC, hacker_id) AS RN,
           submission_date, hacker_id
    FROM Submissions
    GROUP BY submission_date, hacker_id
),

-- List of hackers with maximum submissions per day 
MAX_SUBS_PER_DAY AS (
    SELECT submission_date, hacker_id
    FROM (
        SELECT MIN(RN) AS min_rn
        FROM MAX_SUBMISSIONS
        GROUP BY submission_date
    ) MAX_ENTRY 
    JOIN MAX_SUBMISSIONS MS ON MAX_ENTRY.min_rn = MS.RN
)

-- RESULT 
SELECT UQ.submission_date, unique_hackers_count, Hackers.hacker_id, Hackers.name
FROM UNIQUE_HACKERS_PER_DAY UQ
JOIN MAX_SUBS_PER_DAY MX ON UQ.submission_date = MX.submission_date
JOIN Hackers ON MX.hacker_id = Hackers.hacker_id;


-- DROP TABLE Hackers;
-- DROP TABLE Submissions;