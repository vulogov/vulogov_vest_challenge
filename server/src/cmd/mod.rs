extern crate log;
use clap::{Parser};
use lazy_static::lazy_static;
use std::sync::Mutex;
use std::env;

use jsonrpc_http_server::*;
use jsonrpc_http_server::jsonrpc_core::*;
use rusqlite::{Connection};

pub mod setloglevel;
pub mod app_blotter;
pub mod app_positions;
pub mod app_alarms;
pub mod app_sql;

lazy_static! {
    pub static ref CLI: Mutex<Cli> = {
        let e: Mutex<Cli> = Mutex::new(Cli::parse());
        e
    };
}

lazy_static! {
    pub static ref DB: Mutex<Connection> = {
        let fname: String = env::var("APP_DATABASE_FILE").unwrap();
        let c: Mutex<Connection> = Mutex::new(Connection::open(&fname).unwrap());
        log::debug!("Database been open: {}", &fname);
        c
    };
}

pub fn check_params(p: Params) -> Option<Vec<Value>> {
    let params = match p {
            Params::Array(params) => params,
            _ => {
                log::error!("No params found in request");
                return None;
            }
    };
    if params.len() == 0 {
        log::error!("Empty params");
        return None;
    }
    if env::var("APP_KEY").unwrap() != params[0] {
        log::error!("No APP_KEY found");
        return None;
    }
    return Some(params);
}


pub fn main() {
    let cli = Cli::parse();
    setloglevel::setloglevel(&cli);
    let init_cli = CLI.lock().unwrap();
    log::debug!("Initialize global CLI");
    drop(init_cli);
    log::debug!("app-server tool context initialized ...");
    let bind_addr = match env::var("APPSERVER_BIND") {
        Ok(val) => val,
        Err(err) => { 
            log::error!("APPSERVER_BIND {}", err);
            return;
        }
    };
    log::debug!("app-server will be bound to {}", &bind_addr);
    let db = DB.lock().unwrap();
    drop(db);

    let mut io = IoHandler::default();
    io.add_method("version", |p: Params| {
        let _ = match check_params(p) {
            Some(params) => params,
            None => {
                return Ok(Value::String(
				"Invalid params".to_owned(),
			));
            }
        };
	Ok(Value::String(env!("CARGO_PKG_VERSION").into()))
    });
    io.add_method("blotter", |p: Params| {
        let params = match check_params(p) {
            Some(params) => params,
            None => {
                return Ok(Value::String(
                                "Invalid params".to_owned(),
                        ));
            }
        };
        let query: String = params[1].to_string().trim_matches('"').to_string();
        let res = app_blotter::run(query);
        Ok(res.into())
    });
    io.add_method("positions", |p: Params| {
        let params = match check_params(p) {
            Some(params) => params,
            None => {
                return Ok(Value::String(
                                "Invalid params".to_owned(),
                        ));
            }
        };
        let query: String = params[1].to_string().trim_matches('"').to_string();
        let res = app_positions::run(query);
        Ok(res.into())
    });
    io.add_method("alarms", |p: Params| {
        let params = match check_params(p) {
            Some(params) => params,
            None => {
                return Ok(Value::String(
                                "Invalid params".to_owned(),
                        ));
            }
        };
        let query: String = params[1].to_string().trim_matches('"').to_string();
        let res = app_alarms::run(query);
        Ok(res.into())
    });
    let server = ServerBuilder::new(io)
		.cors(DomainsValidation::AllowOnly(vec![AccessControlAllowOrigin::Null]))
		.start_http(&bind_addr.parse().unwrap())
		.expect("Unable to start RPC server");

    server.wait();

    
}

#[derive(Parser, Clone, Debug)]
#[clap(name = "app-server")]
#[clap(author = "Vladimir Ulogov <vladimir@ulogov.us>")]
#[clap(version = env!("CARGO_PKG_VERSION"))]
#[clap(
    about = "Application server",
    long_about = "Vest interview and take home assignment"
)]
#[command(version, about, long_about = None)]
pub struct Cli {
    /// Turn debugging information on
    #[arg(short, long, action = clap::ArgAction::Count)]
    debug: u8,

}


#[test]
fn test_db_open() {
    let db = DB.lock();
    drop(db);
}

#[test]
fn test_app_access_key() {
    let key: String = std::env::var("APP_KEY").unwrap();
    assert_eq!(key, "helloworld".to_string());
}
