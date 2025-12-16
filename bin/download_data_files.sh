#!/bin/sh

. $HOME/.env.sh

$SFTPCLI -i $SFTPKEY $SFTPUSER@$DATA_SRC:data/trade1.csv $HOME/data/trade1.csv.in
$SFTPCLI -i $SFTPKEY $SFTPUSER@$DATA_SRC:data/trade2.csv $HOME/data/trade2.csv.in

if [ -f $HOME/data/trade1.csv.in ]; then
	mv $HOME/data/trade1.csv.in $HOME/data/trade1.csv
fi

if [ -f $HOME/data/trade2.csv.in ]; then
        mv $HOME/data/trade2.csv.in $HOME/data/trade2.csv
fi
