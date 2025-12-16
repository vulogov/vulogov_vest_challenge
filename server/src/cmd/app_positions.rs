extern crate log;
use crate::cmd;
use jsonrpc_http_server::jsonrpc_core::*;

const POSITIONS_QUERY: &str = r#"select Ticker, count(*)*100.0/(select count(*) from TRADE1) as percentage FROM TRADE1 WHERE TradeDate = ? GROUP by Ticker"#;


pub fn run(param: String) -> Vec<Value> {
    log::debug!("Running positions query with param: {}", &param);
    let res: Vec<Value> = cmd::app_sql::run_select(POSITIONS_QUERY.to_string(), param);
    return res;
}

#[test]
fn test_positions() {
    let res = cmd::app_sql::run_select(POSITIONS_QUERY.to_string(), "2025-01-15".to_string());
    assert_eq!(res.len(), 5);
}
