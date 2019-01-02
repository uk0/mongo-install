#!/bin/bash

###########################获取集群节点数量############
source MONGO_PACKAGE_PATH/env/env.sh

##########################根据分片倍数创建MongoDB分片,并写入fstab##
for((i=0;i<$TD_MDB_SHARD_GROUD_NUM;i++))
do
        for((j=1;j<=$TD_NODE_COUNT;j++))
        do
        let rs_num=$rs_num+1
        let port_num=27018+$rs_num
        let current_rs=$j
        let left_rs=$current_rs-1
        let right_rs=$current_rs+1
        let max_rs=$TD_NODE_COUNT
        if  [ $left_rs -eq 0 ] || [ $left_rs -eq $TD_NODE_COUNT ];
        then
                let left_rs=$TD_NODE_COUNT
        elif [ $right_rs -gt $max_rs ];
        then
                let right_rs=1
        fi
         echo -e "\033[33m-----------[TOD-Shard-$rs_num/mongo_host$current_rs:$port_num,mongo_host$left_rs:$port_num,mongo_host$right_rs:$port_num]----------- \033[0m"
	$MONGO_HOME/bin/mongo mongo_host1:27017 <<EOF
	sh.addShard("TOD-Shard-$rs_num/mongo_host$current_rs:$port_num,mongo_host$left_rs:$port_num,mongo_host$right_rs:$port_num");
	sh.setBalancerState(false);
        exit;
EOF
        done
done
