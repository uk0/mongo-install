#!/bin/bash

MONGO_PACKAGE_PATH=$(cd `dirname $0`; pwd)
export MONGO_PACKAGE_PATH=$(cd `dirname $0`; pwd)

source $MONGO_PACKAGE_PATH/env/env.sh

MONGOS=$(cat $MONGO_PACKAGE_PATH/config | grep MONGOS | awk -F "=" '{print$2}')

#关闭MongoDB

/bin/sh $MONGO_PACKAGE_PATH/run.sh autostop 

##获得mongodb 的文件路径 

echo -e "\033[1m Remove Data  \033[0m"

source $MONGO_PACKAGE_PATH/env/env.sh

OLD_IFS="$IFS"
IFS=","
arrs=($MONGOS)
IFS="$OLD_IFS"
for s1 in "${!arrs[@]}"; do
    echo -e "\033[1m  rmrf shard  data at ${arrs[$s1]} \033[0m"
    ssh "${arrs[$s1]}" "[ -d  $TD_DATA/mongodb ] && rm -rf $TD_DATA/mongodb  || echo Is not Path"
    echo -e "\033[1m  rmrf shard  logs , pids  at ${arrs[$s1]} \033[0m"
    ssh "${arrs[$s1]}" "[ -d  $TD_DATA/logs/mongodb ] && rm -rf $TD_DATA/logs/mongodb  || echo Is not Path"
    ssh "${arrs[$s1]}" "[ -d  $TD_DATA/pids/mongodb ] && rm -rf $TD_DATA/pids/mongodb  || echo Is not Path"
done

##清理文件

##清理zookeepr /mongo

##清理shard 数据 (存储的文件)