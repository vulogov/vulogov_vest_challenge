#!/bin/sh

. $HOME/.env.sh

if [ -f $HOME/data/trade.db ]; then
	echo "Uploading $DBFILE"
	$AWSCLI s3 cp $DBFILE $S3_LOCATION/trade.db
fi
