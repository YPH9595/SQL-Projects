--@AUTHOR Jasmine Abtahi

CREATE TABLE Hackers (
    hacker_id INT,
    name VARCHAR(40)
);

CREATE TABLE Submissions (
    submission_date DATE,
    submission_id INT,
    hacker_id INT,
    score INT
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
INSERT INTO submissions VALUES ('2016-03-01', 8494, 20703, 0);
INSERT INTO submissions VALUES ('2016-03-01', 22403, 53473, 15);
INSERT INTO submissions VALUES ('2016-03-01', 23965, 79722, 60);
INSERT INTO submissions VALUES ('2016-03-01', 30173, 36396, 70);
INSERT INTO submissions VALUES ('2016-03-02', 34928, 20703, 0);
INSERT INTO submissions VALUES ('2016-03-02', 38740, 15758, 60);
INSERT INTO submissions VALUES ('2016-03-02', 42769, 79722, 25);
INSERT INTO submissions VALUES ('2016-03-02', 44364, 79722, 60);
INSERT INTO submissions VALUES ('2016-03-03', 45440, 20703, 0);
INSERT INTO submissions VALUES ('2016-03-03', 49050, 36396, 70);
INSERT INTO submissions VALUES ('2016-03-03', 50273, 79722, 5);
INSERT INTO submissions VALUES ('2016-03-04', 50344, 20703, 0);
INSERT INTO submissions VALUES ('2016-03-04', 51360, 44065, 90);
INSERT INTO submissions VALUES ('2016-03-04', 54404, 53473, 65);
INSERT INTO submissions VALUES ('2016-03-04', 61533, 79722, 45);
INSERT INTO submissions VALUES ('2016-03-05', 72852, 20703, 0);
INSERT INTO submissions VALUES ('2016-03-05', 74546, 38289, 0);
INSERT INTO submissions VALUES ('2016-03-05', 76487, 62529, 0);
INSERT INTO submissions VALUES ('2016-03-05', 82439, 36396, 10);
INSERT INTO submissions VALUES ('2016-03-05', 90006, 36396, 40);
INSERT INTO submissions VALUES ('2016-03-06', 90404, 20703, 0);


--FETCH
SELECT *
FROM Hackers;

SELECT *
FROM Submissions;

-- total number of unique hackers who made at least 1 submission each day (starting on the first day of the contest)
WITH RECURSION AS 
    (SELECT Submissions.submission_date, hacker_id -- BASE
    FROM Submissions,
    (SELECT TOP 1 submission_date -- FOR MAKING THE BASE 
    FROM Submissions
    GROUP BY submission_date
    ORDER BY submission_date
    ) TOP_ONE
    WHERE Submissions.submission_date = TOP_ONE.submission_date

    UNION ALL 
    
    SELECT Submissions.submission_date, Submissions.hacker_id -- RECURSION 
    FROM RECURSION
    JOIN Submissions ON dateadd(DAY, +1, RECURSION.submission_date) = Submissions.submission_date AND RECURSION.hacker_id = Submissions.hacker_id),

    COUNT_SUBS_PER_DAY AS
    (SELECT submission_date, COUNT(DISTINCT hacker_id) AS sum
    FROM RECURSION
    GROUP BY submission_date),

--hacker_id and name of the hacker who made maximum number of submissions each day
    GROUP_MAX_SUBMISSIONS AS
    (SELECT ROW_NUMBER() OVER (ORDER BY submission_date, COUNT(*) DESC, hacker_id) AS RN,
    submission_date, hacker_id, COUNT(*) AS sum
    FROM Submissions
    GROUP BY submission_date, hacker_id), 

    MAX_SUB_PER_DAY AS
    (SELECT submission_date, hacker_id
    FROM (
        SELECT MIN(RN) AS min
        FROM GROUP_MAX_SUBMISSIONS
        GROUP BY submission_date
        ) MAX_ENTRY 
    JOIN GROUP_MAX_SUBMISSIONS ON MAX_ENTRY.min = GROUP_MAX_SUBMISSIONS.RN)
    
--RESULT 
    SELECT COUNT_SUBS_PER_DAY.submission_date, sum, Hackers.hacker_id, name
    FROM COUNT_SUBS_PER_DAY
    JOIN MAX_SUB_PER_DAY ON COUNT_SUBS_PER_DAY.submission_date = MAX_SUB_PER_DAY.submission_date
    JOIN Hackers ON Hackers.hacker_id = MAX_SUB_PER_DAY.hacker_id;

-- DROP TABLE Hackers;
-- DROP TABLE Submissions;
