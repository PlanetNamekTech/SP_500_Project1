-- Historical Data of the S&P 500
SELECT *
FROM SP_500.dbo.sp500_stocks stocks

--Information about the companies of the S&P 500
SELECT *
FROM SP_500..sp500_companies

-- Shortened list with formatted current price
SELECT Symbol, Shortname, Sector, FORMAT(Currentprice,'C') AS 'Current Price', Marketcap, Ebitda
FROM SP_500..sp500_companies

-- Average OPEN price of stocks in list over last 12 years
SELECT Symbol, AVG(stocks.[Open]) average_open,
	MAX(Date) max_date, MIN(Date) min_date
FROM SP_500.dbo.sp500_stocks stocks
GROUP BY Symbol
ORDER BY Symbol

-- Showing average open price compared to current price from different table
SELECT Symbol, FORMAT(AVG(stocks.[Open]),'C') average_open,
	(SELECT Currentprice
	FROM SP_500.dbo.sp500_companies companies
	WHERE stocks.Symbol = companies.Symbol) as current_price
FROM SP_500.dbo.sp500_stocks stocks
WHERE Symbol like 'a%'
GROUP BY Symbol
ORDER BY Symbol

-- Showing how Symbols starting with "A" performed compared to their average
SELECT companies.Symbol, FORMAT(AVG(stocks.[Open]),'C') average_open, 
	FORMAT(Currentprice,'C') as current_price,
	FORMAT(-(1-(Currentprice/AVG(stocks.[Open]))),'P') as percent_off_avg
FROM SP_500.dbo.sp500_stocks stocks INNER JOIN SP_500.dbo.sp500_companies companies
	ON stocks.Symbol = companies.Symbol
WHERE companies.Symbol like 'a%'
GROUP BY companies.Symbol,companies.Currentprice
ORDER BY companies.Symbol

-- Top 25 best performing stocks in the last 12 years (For companies that have been around that long)
SELECT TOP 25
	stocks.Symbol,
	FORMAT(stocks.Adj_Close,'C') as Jan_2010_close, 
	FORMAT(companies.Currentprice,'C') as current_price,
	((Currentprice-Adj_Close)/Adj_Close)*100 as performance
FROM SP_500.dbo.sp500_stocks stocks INNER JOIN SP_500.dbo.sp500_companies companies ON stocks.Symbol = companies.Symbol
WHERE stocks.[Date]= '2010-01-04' AND stocks.Adj_Close IS NOT NULL
ORDER BY performance DESC


--Using CTE to perform calculation for result from aggregate function
--What sectors make up the S&P 500 by percent
--Percent is over 100 because there are 502 companies listed
WITH Percent_of_SP500 (Sector,#stocksinsector)
AS
(
SELECT Sector, COUNT(sector) #stocksinsector
FROM SP_500..sp500_companies
GROUP BY Sector
)
SELECT *, (CAST((#stocksinsector) AS decimal(5,2)) /500)*100 Percent_of_SP500_Index
FROM Percent_of_SP500

--Using a Temp Table to calculate the sector allocation of the S&P 500
DROP TABLE IF EXISTS sp500_sectors
CREATE TABLE sp500_sectors
(
Sector nvarchar(255),
#stocksinsector numeric
)
INSERT INTO sp500_sectors
SELECT Sector, COUNT(sector) #stocksinsector
FROM SP_500..sp500_companies
GROUP BY Sector

SELECT *, (CAST((#stocksinsector) AS decimal(5,2)) /500)*100 Percent_of_SP500_Index
FROM sp500_sectors

-- Creating view to later use in Tableau visualization
CREATE VIEW sp500_sectors_percentage AS
SELECT Sector, COUNT(sector) #stocksinsector
FROM SP_500..sp500_companies
GROUP BY Sector

SELECT *, (CAST((#stocksinsector) AS decimal(5,2)) /500)*100 Percent_of_SP500_Index
FROM sp500_sectors_percentage

--Second view for stock performance
CREATE VIEW sp_500_top_performers AS
SELECT TOP 25
	stocks.Symbol,
	FORMAT(stocks.Adj_Close,'C') as Jan_2010_close, 
	FORMAT(companies.Currentprice,'C') as current_price,
	((Currentprice-Adj_Close)/Adj_Close)*100 as performance
FROM SP_500.dbo.sp500_stocks stocks INNER JOIN SP_500.dbo.sp500_companies companies ON stocks.Symbol = companies.Symbol
WHERE stocks.[Date]= '2010-01-04' AND stocks.Adj_Close IS NOT NULL
ORDER BY performance DESC

--Checking data type of different columns
SELECT *
FROM INFORMATION_SCHEMA.columns
WHERE TABLE_NAME =	'sp_500_top_performers'