#!/bin/bash

TD_MDB_SHARD_GROUD_NUM=1
TD_NODE_COUNT=5

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
        done
done
