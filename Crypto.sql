USE CryptoProject
GO
SELECT TOP (5) * FROM crypto_hist
SELECT TOP(5) * FROM coins_info

GO
-- Creating view #1 marketcap against social media/announcement count
CREATE VIEW socialAnnouncement AS
SELECT coin_id, [name], SUM(market_cap) AS market_cap, (COUNT(website)+COUNT(twitter)+COUNT(message_board)+COUNT(chat)+COUNT(reddit)+COUNT(technical_doc)+COUNT(source_code)+COUNT(announcement)) AS saCount 
FROM (
    SELECT *, MAX([date]) OVER (PARTITION BY coin_id) AS latest_date FROM crypto_hist
) ch
INNER JOIN coins_info ci
ON ch.coin_id = ci.id
WHERE [date] = latest_date
GROUP BY coin_id, [name]
HAVING SUM(market_cap) != 0 AND [name] NOT LIKE '%[[]old]%'

GO

-- Creating view #2 percent change of coins for each year
GO
CREATE VIEW ROI AS
WITH soy AS
(SELECT *, 
ROW_NUMBER() OVER (PARTITION BY coin_id, YEAR([date]) ORDER BY date ASC) AS year_rank,
MIN([date]) OVER (PARTITION BY coin_id, YEAR([date])) AS earliest_of_year FROM crypto_hist),
eoy AS
(SELECT *, 
ROW_NUMBER() OVER (PARTITION BY coin_id, YEAR([date]) ORDER BY date DESC) AS year_rank, 
MAX([date]) OVER (PARTITION BY coin_id, YEAR([date])) AS latest_of_year FROM crypto_hist)
SELECT soy.coin_id, [name], soy.price AS soy_price, eoy.price AS eoy_price, earliest_of_year, latest_of_year, (eoy.price-soy.price)/soy.price AS yearly_per_change FROM soy
INNER JOIN eoy
ON soy.coin_id = eoy.coin_id AND YEAR(soy.[date]) = YEAR(eoy.[date])
INNER JOIN coins_info ci
ON soy.coin_id = ci.id
WHERE soy.year_rank = 1 AND eoy.year_rank = 1 AND soy.date = earliest_of_year AND eoy.[date] = latest_of_year AND [name] NOT LIKE '%[[]old]%'

GO 

-- Creating view #3 specifically showing daily market cap and coin name
CREATE VIEW top_coins AS
SELECT id, [name], market_cap, [date] FROM crypto_hist ch
INNER JOIN coins_info ci
ON ch.coin_id = ci.id
WHERE [name] NOT LIKE '%[[]old]%'

-- Creating view #4 marketshare percent btc/eth/others
GO 
CREATE view market_share AS
SELECT coin_id, [name], [date], market_cap AS market_cap_1, total_daily_marketcap, market_cap/total_daily_marketcap AS market_cap_Percent
FROM(
    SELECT *, SUM(CAST(market_cap AS float)) OVER (PARTITION BY [date]) AS total_daily_marketcap FROM crypto_hist
    ) rp
INNER JOIN coins_info ci
ON rp.coin_id = ci.id
WHERE [name] NOT LIKE '%[[]old]%'