CREATE DATABASE hr
USE hr

SELECT *
FROM [HR Data]

SELECT termdate
FROM [HR Data]
ORDER BY termdate DESC
-------------------FORMAT termdate--------------
--Trong lệnh CONVERT của SQL Server, số 120 đại diện cho kiểu định dạng datetime "ODBC" hoặc "120", là một trong các định dạng chuẩn được hỗ trợ cho ngày tháng trong SQL Server.
UPDATE [HR Data]
SET termdate= FORMAT(CONVERT(DATETIME, LEFT(termdate,19),120),'yyyy-MM-dd')

ALTER TABLE [HR Data]
ADD new_termdate DATE
----copy converted time values from termdate to new_termdate
UPDATE [HR Data]
SET new_termdate = CASE
WHEN termdate IS NOT NULL AND ISDATE(termdate)=1 THEN CAST(termdate AS DATETIME) ELSE NULL END;

--Create new column "age"
ALTER TABLE [HR Data]
ADD age nvarchar(50);

--populate new column with age
UPDATE [HR Data]
SET age=DATEDIFF(YEAR,birthdate, GETDATE());
----------------------------------------------------QUESTIONS TO ANSWER FROM THE DATA---------------------------------------------
--1.What's the age distribution in the company?
------age distribution---------------
SELECT 
	MIN(age) AS YOUNGEST,
	MAX(age) AS OLDEST
FROM [HR Data]
--YOUNGEST: 22
--OLD:59
-----------age group count-----------------
SELECT age_group, COUNT(*) AS count
FROM 
	(SELECT 
		CASE
			WHEN age >=21 AND age<=30 THEN '21 to 30'
			WHEN age >=31 AND age<=40 THEN '31 to 40'
			WHEN age >=41 AND age<=50 THEN '41 to 50'
			ELSE '50+'
		END AS age_group
	 FROM [HR Data]
	 WHERE new_termdate IS NULL) AS S
GROUP BY age_group
ORDER BY age_group
--21 to 30: 4286
--31 to 40: 5067
--41 to 50: 4848
--50+: 4084

--------------age group by gender-----------------------
SELECT age_group, gender,COUNT(*) AS count
FROM 
	(SELECT 
		CASE
			WHEN age >=21 AND age<=30 THEN '21 to 30'
			WHEN age >=31 AND age<=40 THEN '31 to 40'
			WHEN age >=41 AND age<=50 THEN '41 to 50'
			ELSE '50+'
		END AS age_group, gender
	 FROM [HR Data]
	 WHERE new_termdate IS NULL) AS S
GROUP BY age_group, gender
ORDER BY age_group, gender
--21 to 30	Female	        2002
--21 to 30	Male	        2178
--21 to 30	Non-Conforming	106
--31 to 40	Female          2328
--31 to 40	Male	        2588
--31 to 40	Non-Conforming	151
--41 to 50	Female	        2211
--41 to 50	Male	        2501
--41 to 50	Non-Conforming	136
--50+	    Female	        1914
--50+	    Male	        2061
--50+	    Non-Conforming	109

--2.What's the gender breakdown in the company?
SELECT 
	gender,
	COUNT(*) AS Count
FROM [HR Data]
WHERE new_termdate is NULL
GROUP BY gender
ORDER BY gender ASC
--Female	       8455
--Male	           9328
--Non-Conforming	502


--3.How does gender vary across departments and job titles?
SELECT gender, department, COUNT(*) AS Count
FROM [HR Data]
WHERE new_termdate IS NULL
GROUP BY department, gender
ORDER BY department, gender ASC 

--job titles
SELECT 
department, jobtitle,
gender,
count(gender) AS count
FROM [HR Data]
WHERE new_termdate IS NULL
GROUP BY department, jobtitle, gender
ORDER BY department, jobtitle, gender ASC;

--4.What's the race distribution in the company?
SELECT race, count(*) as Count
FROM [HR Data]
WHERE new_termdate IS NULL
GROUP BY  race
ORDER BY race ASC

--5.What's the average length of employment in the company?
SELECT
	AVG(DATEDIFF(year,hire_date, new_termdate)) AS TENURE 
FROM [HR Data]
WHERE new_termdate IS NOT NULL AND new_termdate<=GETDATE()
--6.Which department has the highest turnover rate?
SELECT 
	s.department,
	total_count,
	terminated_count,
	ROUND(CAST(terminated_count AS FLOAT)/ total_count,2)*100 AS turnover_rate
FROM
   (SELECT 
		department,
		count(*) as total_count,
		SUM(CASE 
				WHEN new_termdate IS NOT NULL AND new_termdate <=GETDATE() THEN 1 ELSE 0
			END) AS terminated_count
	FROM [HR Data]
	GROUP BY department) as S
ORDER BY turnover_rate DESC;

--7.What is the tenure distribution for each department?
SELECT 
    department,
    AVG(DATEDIFF(year, hire_date, new_termdate)) AS tenure
FROM 
    [HR Data]
WHERE 
    new_termdate IS NOT NULL 
    AND new_termdate <= GETDATE()
GROUP BY 
    department;

--8.How many employees work remotely for each department?
SELECT location, count(*)
FROM [HR Data]
WHERE new_termdate IS NULL 
group by location
--9.What's the distribution of employees across different states?
SELECT 
 location_state,
 count(*) AS count
FROM [HR Data]
WHERE new_termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;
--10.How are job titles distributed in the company?
SELECT 
 jobtitle,
 count(*) AS count
 FROM [HR Data]
 WHERE new_termdate IS NULL
 GROUP BY jobtitle
 ORDER BY count DESC;
--11.How have employee hire counts varied over time?
SELECT 
	hire_year,
	hires,
		terminations,
 hires - terminations AS net_change,
 (round(CAST(hires-terminations AS FLOAT)/hires, 2)) * 100 AS percent_hire_change
FROM 
	(SELECT 
		YEAR(hire_date) AS hire_year,
		count(*) AS Hires,
		SUM(CASE 
				WHEN new_termdate is not null and new_termdate <= GETDATE() THEN 1 ELSE 0
			END
			) AS terminations
	FROM [HR Data]
	group by YEAR(hire_date)) as s
ORDER BY hire_year,percent_hire_change ASC;
