/* 
		Navigating the Pandemic: A Deep Dive into Covid-19 Data Exploration 
		Skills used: Converting Data Types, Aggregate Functions, Joins, Windows Functions, CTE's, Temp Tables, Creating Views
*/


--SELECT * 
--FROM Portfolio..CovidDeaths

--SELECT * 
--FROM Portfolio..CovidVaccinations

-- what is the estimated percentage of the population that has been affected by COVID-19 in a specific country or region?
SELECT location, date, total_cases, population, (total_cases/population)*100 AS 'PopulationInfected%'
FROM Portfolio..CovidDeaths
WHERE total_cases IS NOT NULL AND population IS NOT NULL AND continent IS NOT NULL
--AND location = 'India'    --Here you can Check for your particutar country
ORDER BY 'PopulationInfected%' DESC

-- what is the mortality rate associated with contracting COVID-19?
SELECT location, date, total_deaths, total_cases, (total_deaths/total_cases)*100 AS 'Death%'
FROM Portfolio..CovidDeaths
WHERE total_deaths IS NOT NULL AND total_cases IS NOT NULL AND continent IS NOT NULL
--AND location = 'India'    --Uncomment this line to check for a particutar country
ORDER BY 'Death%' DESC

-- which countries have the highest infection rates relative to their population size?
SELECT location, population, MAX(total_cases) AS InfectionRate,  MAX((total_cases/population))*100 AS 'PopulationInfected%'
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
--AND location = 'India'    --Uncomment this line to check for a particutar country
GROUP BY location, population
ORDER BY InfectionRate DESC

-- which countries have the highest number of COVID-19 deaths per capita?
SELECT location, MAX(CAST(total_deaths AS INT)) AS DeathCount
FROM Portfolio..CovidDeaths
WHERE total_deaths IS NOT NULL AND continent IS NOT NULL
--AND location = 'India'    --Uncomment this line to check for a particutar country
GROUP BY location
ORDER BY DeathCount DESC

-- Continental Analysis: Unveiling Patterns and Variations Across Regions
-- which continents have the highest number of COVID-19 deaths per capita?
SELECT continent, MAX(CAST(total_deaths AS INT)) AS DeathCount
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathCount DESC

-- Global Data Revealed: Exploring Key Numbers and Insights
SELECT SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS INT)) AS total_new_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS 'Death%'
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL

-- Global Data Revealed: Exploring Key Numbers and Insights chronologically
SELECT date, SUM(new_cases) AS total_new_cases, SUM(CAST(new_deaths AS INT)) AS total_new_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS 'Death%'
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
HAVING SUM(new_cases) IS NOT NULL AND SUM(CAST(new_deaths AS INT)) IS NOT NULL AND SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 IS NOT NULL
ORDER BY date 

-- what is the latest update on the number of COVID-19 vaccinations administered?
SELECT covDths.continent, covDths.location, covDths.date, covDths.population, covVac.new_vaccinations, 
SUM(CONVERT(INT,covVac.new_vaccinations)) OVER (PARTITION BY covDths.location ORDER BY covDths.location, covDths.date) AS total_new_vaccinated
FROM Portfolio..CovidDeaths covDths
JOIN Portfolio..CovidVaccinations covVac
	ON covDths.location = covVac.location
	AND covDths.date = covVac.date
WHERE covDths.continent IS NOT NULL 
ORDER BY covDths.location, covVac.date;

-- what is the latest update on the percentage of the population that has received COVID-19 vaccinations?
-- Performing calculations using Common Table Expressions (CTEs).
WITH NewVac (continent, location, date, population, new_vaccinations, total_new_vaccinated)
AS
(
SELECT covDths.continent, covDths.location, covDths.date, covDths.population, covVac.new_vaccinations, 
SUM(CONVERT(INT,covVac.new_vaccinations)) OVER (PARTITION BY covDths.location ORDER BY covDths.location, covDths.date) AS total_new_vaccinated
FROM Portfolio..CovidDeaths covDths
JOIN Portfolio..CovidVaccinations covVac
	ON covDths.location = covVac.location
	AND covDths.date = covVac.date 
)
SELECT *, (total_new_vaccinated/population)*100 AS new_vaccinated_perc
FROM NewVac
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Performing calculations using temporary tables.
DROP TABLE IF EXISTS  #LatestPopulationVaccinated
CREATE TABLE #LatestPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations INT,
total_new_vaccinated INT
)

INSERT INTO #LatestPopulationVaccinated
SELECT covDths.continent, covDths.location, covDths.date, covDths.population, covVac.new_vaccinations, 
SUM(CONVERT(INT,covVac.new_vaccinations)) OVER (PARTITION BY covDths.location ORDER BY covDths.location, covDths.date) AS total_new_vaccinated
FROM Portfolio..CovidDeaths covDths
JOIN Portfolio..CovidVaccinations covVac
	ON covDths.location = covVac.location
	AND covDths.date = covVac.date
WHERE covDths.continent IS NOT NULL

SELECT *, (total_new_vaccinated/population)*100 AS new_vaccinated_perc
FROM #LatestPopulationVaccinated
WHERE continent IS NOT NULL
ORDER BY location, date;

--Creating a persistent view in a database to store data for subsequent visualizations or analysis.
DROP VIEW IF EXISTS LatestPopulationVaccinated;

CREATE VIEW LatestPopulationVaccinated AS
SELECT covDths.continent, covDths.location, covDths.date, covDths.population, covVac.new_vaccinations, 
SUM(CONVERT(INT,covVac.new_vaccinations)) OVER (PARTITION BY covDths.location ORDER BY covDths.location, covDths.date) AS total_new_vaccinated
FROM Portfolio..CovidDeaths covDths
JOIN Portfolio..CovidVaccinations covVac
	ON covDths.location = covVac.location
	AND covDths.date = covVac.date;

SELECT *, (total_new_vaccinated/population)*100 AS new_vaccinated_perc
FROM LatestPopulationVaccinated
WHERE continent IS NOT NULL
ORDER BY location, date;
