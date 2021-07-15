/*
SQL QUERIES FOR EXTRACTING DATA FROM COVID_Deaths AND COVID_Vaccinations TABLES
*/
--USING COVID_Deaths TABLE 

--1)QUERY TO SELECT ALL THE DATA FROM Deaths TABLE
SELECT *
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL;


--2)QUERY TO SELECT THE USEFUL DATA
SELECT location, date, new_cases, total_cases, new_deaths, total_deaths, population										--We will be using the data in these columns in the following queries
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								--This condition is applied for clarity of the result set because in the dataset, name of the continent is mentioned in location column when it has a NULL value....(1)
ORDER BY 1, 2;																											--The numbers in ORDER BY refer to the position of columns in SELECT statement....(2)


--3)QUERY FOR TOTAL CASES vs TOTAL DEATHS AND DEATH PERCENTAGE
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								--(1)
ORDER BY 1, 2;																											--(2)


--4)QUERY FOR HIGHEST SINGLE DAY SPIKE IN NUMBER OF CASES
SELECT location, MAX(new_cases) AS highest_number
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_number DESC;


--5)QUERY FOR TOTAL CASES vs POPULATION
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								--(1)
ORDER BY 1, 2;																											--(2)


--6)QUERY FOR INFECTION_RATE vs POPULATION
SELECT location, MAX(total_cases) AS total_no_of_cases, population, MAX(total_cases/population)*100 AS infection_rate
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								--(1)
GROUP BY location, population																							--location and population are in the GROUP BY clause because they are not contained in an aggregate function 
ORDER BY infection_rate DESC;																							--The result set data i.e. infection_rate will be arranged in the descending order


--7)QUERY FOR TOTAL DEATHS vs POPULATION
SELECT location, population, MAX(CAST (total_deaths AS int)) AS death_count												--total_deaths column is of (nvarchar(255),null) datatype, to change it to int datatype we used the CAST function
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								--(1)
GROUP BY location, population
ORDER BY death_count DESC;


--8)QUERY FOR TOTAL DEATHS FOR EACH CONTINENT
SELECT continent, SUM(CAST(new_deaths AS int)) AS death_count
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								--(1)
GROUP BY continent
ORDER BY death_count DESC;


--9)QUERY FOR DAILY GLOBAL CASES AND DAILY GLOBAL DEATHS
SELECT date, SUM(new_cases) AS total_daily_cases, SUM(CONVERT(int, new_deaths)) AS total_daily_deaths					--To change the datatype we can either use CAST function or CONVERT function. In this case we used the CONVERT function
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								--(1)
GROUP BY date
ORDER BY 1;																												--(2)


--10)QUERY FOR TOTAL GLOBAL CASES AND TOTAL GLOBAL DEATHS
SELECT SUM(new_cases) AS total_global_cases, SUM(CONVERT(INT, new_deaths)) AS total_global_deaths
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL;


--USING THE COVID_Vaccinations TABLE 

--11)QUERY TO SELECT ALL THE DATA FROM VACCINATIONS TABLE
SELECT *
FROM Tutorial_Project..COVID_Vaccinations
WHERE continent IS NOT NULL;																							--(1)


--12)QUERY TO JOIN THE DEATHS TABLE AND VACCINATIONS TABLE
SELECT *
FROM Tutorial_Project..COVID_Deaths AS d																				--d is the ALIAS for the table
JOIN Tutorial_Project..COVID_Vaccinations AS v																			--v is the ALIAS for the table
ON d.date = v.date AND d.location = v.location;																			--Join performed on common columns in both the tables


--13)QUERY FOR DAILY CUMULATIVE TESTING
SELECT location, date, CONVERT(int, new_tests) AS new_tests, SUM(CONVERT(int, new_tests)) OVER (PARTITION BY location ORDER BY location, date) AS cumulative_tests
FROM Tutorial_Project..COVID_Vaccinations
WHERE continent IS NOT NULL
GROUP BY location, date, new_tests;


--14)QUERY FOR DAILY VACCINATIONS FOR A LOCATION W.R.T IT'S POPULATION
SELECT d.location, d.date, d.population, v.new_vaccinations
FROM Tutorial_Project..COVID_Deaths d																					--We can also ALIAS a table without using AS keyword
JOIN Tutorial_Project..COVID_Vaccinations v
ON d.date = v.date AND d.location = v.location
WHERE d.continent IS NOT NULL 
ORDER BY 1, 2;


--15)QUERY FOR DAILY CUMULATIVE VACCINATIONS
SELECT d.location AS location, d.date AS date, d.population AS population, v.new_vaccinations AS new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
FROM Tutorial_Project..COVID_Deaths AS d
JOIN Tutorial_Project..COVID_Vaccinations AS v
ON d.date = v.date AND d.location = v.location
WHERE d.continent IS NOT NULL 
ORDER BY 1, 2;


--16)QUERY FOR TOTAL POPULATION vs TOTAL VACCINATIONS OR PERCENTAGE OF PEOPLE VACCINATED ON A DAILY BASIS

  --Now there are two ways of executing the query for the desired result. First way is using a WITH clause.

    --USING WITH CLAUSE
	WITH PopvsVacc(location, date, population, new_vaccinations, cumulative_vaccinations)
	AS (SELECT d.location AS location, d.date AS date, d.population AS population, v.new_vaccinations AS new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
    FROM Tutorial_Project..COVID_Deaths AS d
    JOIN Tutorial_Project..COVID_Vaccinations AS v
    ON d.date = v.date AND d.location = v.location
    WHERE d.continent IS NOT NULL)
    SELECT location, date, population, new_vaccinations, cumulative_vaccinations, (cumulative_vaccinations/population)*100 AS percentage_vaccinated
    FROM PopvsVacc
    ORDER BY location;


  --The second way of executing the query is by using a sub-query.

    --USING SUB-QUERY
	SELECT location, date, population, new_vaccinations, cumulative_vaccinations, (cumulative_vaccinations/population)*100 AS percentage_vaccinated
	FROM(SELECT d.location AS location, d.date AS date, d.population AS population, v.new_vaccinations AS new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
		 FROM Tutorial_Project..COVID_Deaths AS d
		 JOIN Tutorial_Project..COVID_Vaccinations AS v
		 ON d.date = v.date AND d.location = v.location
		 WHERE d.continent IS NOT NULL) AS PopvsVacc
	ORDER BY location;
	

--17)QUERY FOR TOTAL VACCINATIONS DONE IN A LOCATION
SELECT location, population, SUM(new_vaccinations) AS total_vaccinations_done
FROM(SELECT d.location AS location, d.date AS date, d.population AS population, CONVERT(int,v.new_vaccinations) AS new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
	 FROM Tutorial_Project..COVID_Deaths AS d
	 JOIN Tutorial_Project..COVID_Vaccinations AS v
	 ON d.date = v.date AND d.location = v.location
	 WHERE d.continent IS NOT NULL) AS PopvsVacc
GROUP BY location, population
ORDER BY location;


--18)QUERY FOR TOTAL POPULATION vs POPULATION FULLY VACCINATED
SELECT v.location, d.population, MAX(CONVERT(int, v.people_fully_vaccinated)) AS population_fully_vaccinated
FROM Tutorial_Project..COVID_Vaccinations AS v
JOIN Tutorial_Project..COVID_Deaths AS d
ON v.location = d.location 
WHERE v.continent IS NOT NULL
GROUP BY v.location, population
ORDER BY population_fully_vaccinated DESC;




--CREATING VIEWS FOR THE ABOVE QUERIES FOR VIZUALIZATION

--1) VIEW FOR DEATH PERCENTAGE
GO
CREATE VIEW Death_Percentage 
AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL;
GO


--2) VIEW FOR HIGHEST SINGLE DAY SPIKE
GO
CREATE VIEW Highest_Single_Day_Spike
AS
SELECT location, MAX(new_cases) AS highest_number
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL
GROUP BY location;
GO


--3) VIEW FOR INFECTION RATE
GO
CREATE VIEW Infection_Rate
AS
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infection_rate
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL;
GO


--4) VIEW FOR INFECTION RATE VS POPULATION
GO
CREATE VIEW Infection_Rate_vs_Population
AS
SELECT location, MAX(total_cases) AS total_no_of_cases, population, MAX(total_cases/population)*100 AS infection_rate
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								
GROUP BY location, population;
GO

--5) VIEW FOR DEATH COUNT VS POPULATION
GO
CREATE VIEW Death_Count_vs_Population
AS
SELECT location, population, MAX(CAST (total_deaths AS int)) AS death_count								
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								
GROUP BY location, population;
GO


--6) VIEW FOR TOTAL DEATH COUNT FOR EACH CONTINENT
GO
CREATE VIEW Death_Count
AS
SELECT continent, MAX(CAST(total_deaths AS int)) AS death_count
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								
GROUP BY continent;
GO


--7) VIEW FOR GLOBAL CASES AND GLOBAL DEATHS
GO
CREATE VIEW Global_Cases_Global_Deaths
AS
SELECT date, SUM(new_cases) AS total_daily_cases, SUM(CONVERT(int, new_deaths)) AS total_daily_deaths				
FROM Tutorial_Project..COVID_Deaths
WHERE continent IS NOT NULL																								
GROUP BY date;
GO


--8) VIEW FOR DAILY CUMULATIVE TESTING
GO
CREATE VIEW Cumulative_Testing_daily
AS
SELECT location, date, CONVERT(int, new_tests) AS new_tests, SUM(CONVERT(int, new_tests)) OVER (PARTITION BY location ORDER BY location, date) AS cumulative_tests
FROM Tutorial_Project..COVID_Vaccinations
WHERE continent IS NOT NULL
GROUP BY location, date, new_tests;
GO


--9) VIEW FOR DAILY VACCINATIONS W.R.T LOCATION
GO
CREATE VIEW Daily_Vaccinations_Locationwise
AS
SELECT d.location, d.date, d.population, v.new_vaccinations
FROM Tutorial_Project..COVID_Deaths d																				
JOIN Tutorial_Project..COVID_Vaccinations v
ON d.date = v.date AND d.location = v.location
WHERE d.continent IS NOT NULL;
GO


--10) VIEW FOR DAILY CUMULATIVE VACCINATIONS
GO
CREATE VIEW Daily_Cumulative_Vaccinations
AS
SELECT d.location AS location, d.date AS date, d.population AS population, v.new_vaccinations AS new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
FROM Tutorial_Project..COVID_Deaths AS d
JOIN Tutorial_Project..COVID_Vaccinations AS v
ON d.date = v.date AND d.location = v.location
WHERE d.continent IS NOT NULL;
GO


--11) VIEW FOR POPULATION VS VACCINATIONS
GO
CREATE VIEW Population_vs_Vaccinations
AS
SELECT location, date, population, new_vaccinations, cumulative_vaccinations, (cumulative_vaccinations/population)*100 AS percentage_vaccinated
	FROM(SELECT d.location AS location, d.date AS date, d.population AS population, v.new_vaccinations AS new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
		 FROM Tutorial_Project..COVID_Deaths AS d
		 JOIN Tutorial_Project..COVID_Vaccinations AS v
		 ON d.date = v.date AND d.location = v.location
		 WHERE d.continent IS NOT NULL) AS PopvsVacc;
GO


--12) VIEW FOR TOTAL VACCINATIONS DONE IN A LOCATION
GO
CREATE VIEW Locationwise_Vaccinations
AS
SELECT location, population, SUM(new_vaccinations) AS total_vaccinations_done
FROM(SELECT d.location AS location, d.date AS date, d.population AS population, CONVERT(int,v.new_vaccinations) AS new_vaccinations, SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS cumulative_vaccinations
	 FROM Tutorial_Project..COVID_Deaths AS d
	 JOIN Tutorial_Project..COVID_Vaccinations AS v
	 ON d.date = v.date AND d.location = v.location
	 WHERE d.continent IS NOT NULL) AS PopvsVacc
GROUP BY location, population;
GO


--13) VIEW FOR TOTAL POPULATION VS FULLY VACCINATED POPULATION
GO
CREATE VIEW Population_vs_Fully_Vaccinated
AS
SELECT v.location, d.population, MAX(CONVERT(int, v.people_fully_vaccinated)) AS population_fully_vaccinated
FROM Tutorial_Project..COVID_Vaccinations AS v
JOIN Tutorial_Project..COVID_Deaths AS d
ON v.location = d.location 
WHERE v.continent IS NOT NULL
GROUP BY v.location, population;
GO
