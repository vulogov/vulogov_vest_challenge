extern crate log;
use crate::cmd;
use jsonrpc_http_server::jsonrpc_core::*;

const ALARMS_QUERY: &str = r#"
SELECT
    a.AccountID,
    CASE
        WHEN MAX(
            CASE
                WHEN a.net_qty > 0 THEN a.net_qty * 1.0 / t.total_net_qty
                ELSE 0
            END
        ) > 0.2
        THEN 'TRUE'
        ELSE 'FALSE'
    END as has_over_20_percent
FROM (
    SELECT
        AccountID,
        Ticker,
        SUM(
            CASE
                WHEN UPPER(TradeType) = 'BUY' THEN Quantity
                WHEN UPPER(TradeType) = 'SELL' THEN -Quantity
                ELSE 0
            END
        ) as net_qty
    FROM TRADE1
    WHERE TradeDate = ?
    GROUP BY AccountID, Ticker
) a
JOIN (
    SELECT
        Ticker,
        SUM(
            CASE
                WHEN UPPER(TradeType) = 'BUY' THEN Quantity
                WHEN UPPER(TradeType) = 'SELL' THEN -Quantity
                ELSE 0
            END
        ) as total_net_qty
    FROM TRADE1
    WHERE TradeDate = ?
    GROUP BY Ticker
) t ON a.Ticker = t.Ticker
WHERE t.total_net_qty > 0  -- Avoid division by zero
GROUP BY a.AccountID
ORDER BY a.AccountID;
"#;


pub fn run(param: String) -> Vec<Value> {
    log::debug!("Running alarms query with param: {}", &param);
    let res: Vec<Value> = cmd::app_sql::run_select_two_params(ALARMS_QUERY.to_string(), param);
    return res;
}

#[test]
fn test_blotter() {
    let res = cmd::app_sql::run_select_two_params(ALARMS_QUERY.to_string(), "2025-01-15".to_string());
    assert_eq!(res.len(), 4);
}

