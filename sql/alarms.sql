-- Based on Quantity holdings
SELECT 
    a.AccountID,
    CASE 
        WHEN MAX(a.account_qty * 1.0 / t.total_qty) > 0.2 
        THEN 'TRUE' 
        ELSE 'FALSE' 
    END as has_over_20_percent
FROM (
    SELECT 
        AccountID,
        Ticker,
        SUM(Quantity) as account_qty
    FROM TRADE1
    WHERE TradeDate = '2025-01-15'
    GROUP BY AccountID, Ticker
) a
JOIN (
    SELECT 
        Ticker,
        SUM(Quantity) as total_qty
    FROM TRADE1
    WHERE TradeDate = '2025-01-15'
    GROUP BY Ticker
) t ON a.Ticker = t.Ticker
GROUP BY a.AccountID
ORDER BY a.AccountID;
