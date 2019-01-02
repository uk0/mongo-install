#!/bin/bash
############
# init rsX #
############

###########################获取集群节点数量############
source MONGO_PACKAGE_PATH/env/env.sh

##########################根据分片倍数创建MongoDB分片,并写入fstab##
for((i=0;i<$TD_MDB_SHARD_GROUD_NUM;i++))
do
        for((j=1;j<=$TD_NODE_COUNT;j++))
        do
        let increment_rs=$i*$TD_NODE_COUNT
        let rs_num=$rs_num+1
        let port_num=27018+$rs_num
        let current_rs=$j
        let left_rs=$current_rs-1
        let right_rs=$current_rs+1
        let max_rs=$TD_NODE_COUNT
        if  [ $left_rs -eq 0 ] || [ $left_rs -eq $increment_rs ];
        then
                let left_rs=$TD_NODE_COUNT
        elif [ $right_rs -gt $max_rs ];
        then
                let right_rs=1
        fi
        echo -e "\033[33m-----------$MONGO_HOME/bin/mongo mongo_host$j:$port_num----------- \033[0m"

        $MONGO_HOME/bin/mongo mongo_host$j:$port_num <<EOF
        config={_id:"TOD-Shard-$rs_num",
                members:[
                        {_id:0,host:"mongo_host$current_rs:$port_num",priority:2},
                        {_id:1,host:"mongo_host$left_rs:$port_num"},
                        {_id:2,host:"mongo_host$right_rs:$port_num"}],
                settings:{getLastErrorDefaults:{w:"majority",wtimeout:5000}}};
        rs.initiate(config);
        exit;
EOF
        done
done

