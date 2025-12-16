#!/bin/sh

. $HOME/.env.sh_uploaded

echo "Starting $APPSERVER_BIN"

nohup $APPSERVER_BIN &

