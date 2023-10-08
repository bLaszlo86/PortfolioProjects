-- A lekérdezések Microsoft SQL Server-ben történtek.


SELECT *
FROM PortfolioProject..CovidDeaths

SELECT *
FROM PortfolioProject..CovidVaccinations


-- Az adatok kiválasztása, amivel dolgozni fogok.

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Az összes eset, valamint összes halál összevetése.
-- A halálozás valószínûségének megtekintése, ha Magyarországon fertõzõdik meg az ember.

SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float)) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Hungary'
and continent is not null 
ORDER BY 1,2


-- Az összes eset és a lakosság összevetése.
-- A lakosság mennyi százaléka fertõzõdött meg Covid által.

SELECT Location, date, population, total_cases, (total_cases/population) * 100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'Hungary'
ORDER BY 1,2


-- Országok a legmagasabb fertõzõdési rátával, összehasonlítva a lakossággal.

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc


-- A legmagasabb halálozási számok.

SELECT Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY Location
ORDER BY TotalDeathCount desc


-- BONTSUK LE A LEKÉRDEZÉSEKET KONTINENSEKRE

-- Kontinensek a legmagasabb halálozási rátával a lakossághoz mérve.

SELECT location, SUM(cast(new_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null 
and location not in ('World', 'European Union', 'International', 'High income', 'Low income', 'Lower middle income', 'Upper middle income')
GROUP BY location
ORDER BY TotalDeathCount desc


-- Globális számok

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
--Group By date
ORDER BY 1,2


-- Össz lakosság és a beoltottság mértéke

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2, 3


-- CTE használata az elõzõ lekérdezés használatával.

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
WHERE cd.continent IS NOT NULL
-- ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVsVac


-- Ugyanaz, csak ideiglenes tábla felhasználásával.

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
-- WHERE cd.continent IS NOT NULL
-- ORDER BY 2, 3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- View tábla használata, késõbbi vizuális megjelenítés végett.

Create View PercentPopulationVaccinated as
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) OVER 
(Partition by cd.location Order by cd.location, CONVERT(date, cd.date)) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null 
