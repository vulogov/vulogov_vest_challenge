extern crate log;
use crate::cmd;
use jsonrpc_http_server::jsonrpc_core::*;

const BLOTTER_QUERY: &str = r#"SELECT * FROM TRADE1 WHERE TradeDate=?"#;

pub fn run(param: String) -> Vec<Value> {
    log::debug!("Running bloater query with param: {}", &param);
    let res: Vec<Value> = cmd::app_sql::run_select(BLOTTER_QUERY.to_string(), param);
    return res;
}

#[test]
fn test_blotter() {
    let res = cmd::app_sql::run_select(BLOTTER_QUERY.to_string(), "2025-01-15".to_string());
    assert_eq!(res.len(), 10);
}

