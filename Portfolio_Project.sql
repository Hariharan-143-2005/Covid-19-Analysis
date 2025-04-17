-- SELECTING ESESNTIAL DATA FROM DATASET


SELECT continent, location, CAST(date AS date) as date, population, total_cases, total_tests, total_deaths
FROM Portfolio_Project..CovidDeaths;

-- FIND DEATH PERCENTAGE

SELECT continent, location, date, population, total_cases, total_tests, total_deaths, 
       ROUND((ISNULL(total_deaths, 0) / NULLIF(total_cases, 0)) * 100,2) AS deaths_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY population DESC;

 
 
 -- FINDING DEATH PERCENTAGE IN MY COUNTRY


SELECT continent, location, CAST(date AS date) AS date, population, total_cases, total_tests, total_deaths, 
       CONCAT(ROUND((ISNULL(total_deaths, 0) / NULLIF(total_cases, 0)) * 100, 2), '%') AS deaths_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL AND location = 'INDIA'
ORDER BY deaths_percentage DESC, date;


-- FINDING HOW MAN PEOPLES ARE GETTING AFFECTED


SELECT continent, location, date, population, total_cases, total_deaths,
       (ISNULL(total_cases, 0) / NULLIF(population, 0)) * 100 AS affected_percentage,
       (ISNULL(total_deaths, 0) / NULLIF(population, 0)) * 100 AS death_percentage
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY affected_percentage DESC;



--VACINATED PEOPLE IN INDIA

SELECT continent,location,date,total_tests,positive_rate,total_vaccinations
FROM Portfolio_Project..CovidVaccinations
WHERE UPPER(location) = 'INDIA'
AND total_vaccinations IS NOT NULL
ORDER BY date DESC


-- TOP 10 INFECTED COUNTRY


SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS Total_Deaths
FROM Portfolio_Project..CovidDeaths
WHERE continent IS NOT NULL AND ISNUMERIC(total_deaths) = 1
GROUP BY location
ORDER BY Total_Deaths DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

--SHOWING COUNTRY WHICH HAS HIGH DEATH COUNT

WITH RankedDeaths AS (
    SELECT 
        location,
        CAST(date AS DATE) AS date,
        population,
        total_deaths,
        total_cases,
        ROW_NUMBER() OVER (PARTITION BY location ORDER BY total_deaths DESC) AS rn
    FROM 
        Portfolio_Project..CovidDeaths
    WHERE 
        continent IS NOT NULL
        AND total_deaths IS NOT NULL
        AND total_cases IS NOT NULL
)
SELECT 
    location,
    date,
    population,
    CAST(total_deaths AS int) AS max_total_deaths,
    CONCAT(CAST(ROUND((CAST(total_deaths AS FLOAT) * 100.0) / NULLIF(total_cases, 0), 2) AS VARCHAR(10)), '%') AS deaths_percentage
FROM 
    RankedDeaths
WHERE 
    rn = 1
ORDER BY 
    max_total_deaths DESC;


 --Total number of vaccinations vs total cases per country

 SELECT d.location, 
       MAX(d.total_cases) AS Total_Cases, 
       CONVERT(INT,MAX(v.total_vaccinations)) AS Total_Vaccinations
FROM CovidDeaths d
JOIN CovidVaccinations v ON d.location = v.location AND d.date = v.date
WHERE D.continent IS NOT NULL
GROUP BY d.location 
ORDER BY Total_Vaccinations DESC

--Total Population vs Total Vaccinated

SELECT 
    d.location, 
    MAX(d.population) AS Total_Population,
    MAX(v.total_vaccinations) AS Total_Vaccinations,
    ROUND(CAST(MAX(v.total_vaccinations) AS FLOAT) / NULLIF(MAX(d.population), 0) * 100, 2) AS Vaccination_Percentage
FROM Portfolio_Project..CovidDeaths d
JOIN Portfolio_Project..CovidVaccinations v 
  ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
GROUP BY d.location
ORDER BY Vaccination_Percentage DESC;

--Rolling 7-Day Average of New Cases per Country

WITH DailyCases AS (
    SELECT 
        location,
        date,
        population,
        total_cases,
        LAG(total_cases) OVER (PARTITION BY location ORDER BY date) AS prev_day_cases
    FROM Portfolio_Project..CovidDeaths
    WHERE continent IS NOT NULL
),
NewCases AS (
    SELECT 
        location,
        date,
        population,
        ISNULL(total_cases - prev_day_cases, 0) AS new_cases
    FROM DailyCases
),
RollingAverage AS (
    SELECT 
        location,
        date,
        population,
        new_cases,
        ROUND(AVG(new_cases * 1.0) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_7_days
    FROM NewCases
)
SELECT *
FROM RollingAverage
WHERE date BETWEEN '2021-04-01' AND '2021-04-15'
ORDER BY rolling_avg_7_days DESC;


-- TRACK % of population vaccinated over time with CTE

WITH VaccPop AS (
    SELECT 
        v.location,
        v.date,
        v.total_vaccinations,
        d.population
    FROM Portfolio_Project..CovidVaccinations v
    JOIN Portfolio_Project..CovidDeaths d
      ON v.location = d.location AND v.date = d.date
    WHERE v.total_vaccinations IS NOT NULL
      AND d.population IS NOT NULL
      AND d.continent IS NOT NULL
),
VaccinatedPercent AS (
    SELECT 
        location,
        date,
        total_vaccinations,
        population,
        ROUND(CAST(total_vaccinations AS FLOAT) / NULLIF(population, 0) * 100, 2) AS percent_vaccinated
    FROM VaccPop
)
SELECT *
FROM VaccinatedPercent
WHERE location = 'India'  -- change or remove for global view
ORDER BY date;

