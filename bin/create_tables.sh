#!/bin/sh

. $HOME/.env.sh

if [ -f $DBFILE ]; then
	echo "Removing old file $DBFILE"
	rm -f $DBFILE
fi

cd $HOME/data

$DBCLI $DBFILE < $HOME/sql/trade.sql
$DBCLI $DBFILE < $HOME/sql/create_table1.sql
$DBCLI $DBFILE < $HOME/sql/create_table2.sql
