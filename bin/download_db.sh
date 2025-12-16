#!/bin/sh

. $HOME/.env.sh_uploaded

echo "Uploading $DBFILE"
$AWSCLI s3 cp $S3_LOCATION/trade.db $HOME/db/trade.db
