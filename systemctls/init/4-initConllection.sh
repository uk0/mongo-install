#!/bin/bash

source MONGO_PACKAGE_PATH/env/env.sh

let SHARDS_NUM=$TD_NODE_COUNT*$TD_MDB_SHARD_GROUD_NUM

$MONGO_HOME/bin/mongo mongo_host1:27017 <<EOF
sh.enableSharding("nosqlDb")
use admin
db.runCommand({shardcollection:"nosqlDb.mongodb",key:{_id:'hashed'},numInitialChunks:$SHARDS_NUM})
use nosqlDb
db.mongodb.ensureIndex({INDEX_KEY:'hashed'})

sh.enableSharding("scanDataLog")
use admin
db.runCommand({shardcollection:"scanDataLog.scanDataLog",key:{_id:'hashed'},numInitialChunks:$SHARDS_NUM})
use scanDataLog
db.scanDataLog.ensureIndex({BatchEndTime:1})
db.scanDataLog.ensureIndex({ServiceName:'hashed'})
db.scanDataLog.ensureIndex({CollectionName:1})
db.scanDataLog.ensureIndex({DbName:1})
db.scanDataLog.ensureIndex({SortKey:1})
db.scanDataLog.ensureIndex({Complete:1})
exit
EOF