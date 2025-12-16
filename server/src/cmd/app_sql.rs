extern crate log;

use crate::cmd;
use jsonrpc_http_server::jsonrpc_core::*;

pub fn run_select(query: String, param: String) -> Vec<Value> {
    let db = cmd::DB.lock().unwrap();
    let mut res: Vec<Value> = Vec::new();
    let mut stmt = db.prepare(&query).unwrap();
    let mut rows = stmt.query(rusqlite::params![param]).unwrap();
    while let Some(row) = rows.next().unwrap() {
        res.push(Value::String(format!("{:?}", &row)));
    }
    res
}

pub fn run_select_two_params(query: String, param: String) -> Vec<Value> {
    let db = cmd::DB.lock().unwrap();
    let mut res: Vec<Value> = Vec::new();
    let mut stmt = db.prepare(&query).unwrap();
    let mut rows = stmt.query(rusqlite::params![param, param]).unwrap();
    while let Some(row) = rows.next().unwrap() {
        res.push(Value::String(format!("{:?}", &row)));
    }
    res
}

#[test]
fn test_select() {
    let res = run_select("select * from TRADE1 where TradeDate = ?".to_string(), "2025-01-15".to_string());
    assert_eq!(res.len(), 10 as usize);
}
