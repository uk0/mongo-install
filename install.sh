#!/bin/bash

####### 配置环境变量#######

MONGO_PACKAGE_PATH=$(cd `dirname $0`; pwd)
export MONGO_PACKAGE_PATH=$(cd `dirname $0`; pwd)

source $MONGO_PACKAGE_PATH/env/env.sh

#解压
echo "解压 <Mongo"
MONGO_PACKAGE_PATH=$(pwd)
source $MONGO_PACKAGE_PATH/env/env.sh
tar -zxvf $MONGO_PACKAGE_PATH/bin/mongodb.tar.gz -C $TD_BASE

# install storm
echo -e "\033[31m Install Mongo  \033[0m "

# 获取Mongo Config
ROUTE_SERVER=$(cat $MONGO_PACKAGE_PATH/config | grep ROUTE_SERVER | awk -F "=" '{print$2}')
CONFIG_PORT_SERVER=$(cat $MONGO_PACKAGE_PATH/config | grep CONFIG_PORT_SERVER | awk -F "=" '{print$2}')
CONFIG_SERVER=$(cat $MONGO_PACKAGE_PATH/config | grep CONFIG_SERVER | awk -F "=" '{print$2}')
INIT_CFS=$(cat $MONGO_PACKAGE_PATH/config | grep INIT_CFS | awk -F "=" '{print$2}')
MONGOS=$(cat $MONGO_PACKAGE_PATH/config | grep MONGOS | awk -F "=" '{print$2}')
# 获取配置文件内的 副本集Name
MONGO_REPLSET_NAME=$(cat $MONGO_PACKAGE_PATH/config | grep MONGO_REPLSET_NAME | awk -F "=" '{print$2}')
MONGO_MAX_CONNS=$(cat $MONGO_PACKAGE_PATH/config | grep MONGO_MAX_CONNS | awk -F "=" '{print$2}')
SHARD_NODE=$(cat $MONGO_PACKAGE_PATH/config | grep SHARD_NODE | awk -F "=" '{print$2}')
# mongos、config server、shard、replica set
# 替换run,stop脚本里面的环境变量为真实地址 [批量扫描]

MONGO_PACKAGE_PATH_STR=$(echo $MONGO_PACKAGE_PATH | sed 's#\/#\\\/#g')

sed -i "s/MONGO_PACKAGE_PATH/$MONGO_PACKAGE_PATH_STR/g" $(grep MONGO_PACKAGE_PATH -rl $MONGO_PACKAGE_PATH/systemctls/bin/)
#替换 sh下的脚本
sed -i "s/MONGO_PACKAGE_PATH/$MONGO_PACKAGE_PATH_STR/g" $(grep MONGO_PACKAGE_PATH -rl $MONGO_PACKAGE_PATH/systemctls/init/)

######### 启动config server #########

######### 给Core 准备环境变量 #########
export MONGO_REPLSET_NAME=$MONGO_REPLSET_NAME
export MONGO_MAX_CONNS=$MONGO_MAX_CONNS
export MONGO_DATA=$TD_DATA
######### Core #####################
# 环境变量填充
cat $MONGO_HOME/conf/config_t.conf |
	awk '$0 !~ /^\s*#.*$/' |
	sed 's/[ "]/\\&/g' |
	while read -r line; do
		eval echo ${line}
	done >$MONGO_HOME/conf/config.conf
######### 配置目录检测 #########

source $MONGO_PACKAGE_PATH/env/env.sh

OLD_IFS="$IFS"
IFS=","
arrs=($SHARD_NODE)
IFS="$OLD_IFS"
for s1 in "${!arrs[@]}"; do

	echo -e "\033[1m 检查文件目录是否存在 ${arrs[$s1]}  $TD_DATA/pids/mongodb \033[0m "
	ssh "${arrs[$s1]}" "[ -d  $TD_DATA/pids/mongodb   ] && echo mkdir $TD_DATA/pids/mongodb   ok || mkdir -p $TD_DATA/pids/mongodb"
	
	echo -e "\033[1m 检查文件目录是否存在 ${arrs[$s1]}  $TD_DATA/logs/mongodb \033[0m "
	ssh "${arrs[$s1]}" "[ -d  $TD_DATA/logs/mongodb   ] && echo mkdir $TD_DATA/logs/mongodb   ok || mkdir -p $TD_DATA/logs/mongodb"

	echo -e "\033[1m 检查文件目录是否存在 ${arrs[$s1]}  $TD_DATA/mongodb/data/configsrv \033[0m "
	ssh "${arrs[$s1]}" "[ -d  $TD_DATA/mongodb/data/configsrv  ] && echo mkdir $TD_DATA/mongodb/data/configsrv   ok || mkdir -p $TD_DATA/mongodb/data/configsrv"
done
#######################scp########################
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arr=($MONGOS)
IFS="$OLD_IFS"
for s in ${arr[@]}
do
	 echo -e  "\033[1m 分发 mongo install  all script at $s \033[0m"
	 scp -r $MONGO_PACKAGE_PATH "$s":$TD_BASE
	echo -e  "\033[1m 分发 mongodb bin at $s \033[0m"
	 scp -r $MONGO_HOME "$s":$TD_BASE
done

######### 启动 config server #########
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arrs=($CONFIG_SERVER)
IFS="$OLD_IFS"
for s1 in "${!arrs[@]}"; do
	echo -e "\033[32m start ${arrs[$s1]} config server \033[0m"
	ssh "${arrs[$s1]}" $MONGO_PACKAGE_PATH/systemctls/bin/mongodb-cfgserver.service.run 
done




########### start shard##############

# source $MONGO_PACKAGE_PATH/env/env.sh
# OLD_IFS="$IFS"
# IFS=","
# arr=($MONGOS)
# IFS="$OLD_IFS"
# for s1 in "${!arr[@]}";do
# 	num=${#arrs[@]} 
# 	 for ((i=0;i<num;i++)){
# 		 echo -e "\033[1m ${arr[$s]}   start shard  $(($s1 + 1 + $i)) \033[0m"
# 		 echo " $MONGO_HOME/bin/mongod -f $MONGO_HOME/conf/shard$(($s1 + 1 + $i)).conf"
		 
# 		ssh "${arr[$s]}" $MONGO_HOME/bin/mongod -f $MONGO_HOME/conf/shard$(($s1 + 1 + $i)).conf
# 	 }
# done


$MONGO_PACKAGE_PATH/systemctls/init/1-initCfgserver.sh

sleep 5s

######### 启动 route server #########
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arrs=($ROUTE_SERVER)
IFS="$OLD_IFS"
for s1 in "${!arrs[@]}"; do
	echo -e "\033[32m start ${arrs[$s1]} route server \033[0m"
	ssh "${arrs[$s1]}" $MONGO_PACKAGE_PATH/systemctls/bin/mongodb-router.service.run 
done

echo "starting mongodb,please wait.................."
####################init Replica##########################
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arrs=($MONGOS)
IFS="$OLD_IFS"

for((i=0;i<$TD_MDB_SHARD_GROUD_NUM;i++));do
	for s1 in "${!arrs[@]}"; do
	######### 给Core 2 准备环境变量 #########
    export SCRIPT_CURR="$MONGO_PACKAGE_PATH/systemctls/bin/mongodb-shard.service.run $i CURR"
	export SCRIPT_NEXT="$MONGO_PACKAGE_PATH/systemctls/bin/mongodb-shard.service.run $i NEXT"
	export SCRIPT_PREV="$MONGO_PACKAGE_PATH/systemctls/bin/mongodb-shard.service.run $i PREV"
	######### Core 2 #####################
	# 环境变量填充
	cat $MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard.run.template |
		awk '$0 !~ /^\s*#.*$/' |
		sed 's/[ "]/\\&/g' |
		while read -r line; do
			eval echo ${line}
		done >$MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.run
	done
done 

for((i=0;i<$TD_MDB_SHARD_GROUD_NUM;i++));do
	for s1 in "${!arrs[@]}"; do
	######### 给Core 2 准备环境变量 #########
    export SCRIPT_CURR="$MONGO_PACKAGE_PATH/systemctls/bin/mongodb-shard.service.stop $i CURR"
	export SCRIPT_NEXT="$MONGO_PACKAGE_PATH/systemctls/bin/mongodb-shard.service.stop $i NEXT"
	export SCRIPT_PREV="$MONGO_PACKAGE_PATH/systemctls/bin/mongodb-shard.service.stop $i PREV"
	######### Core 2 #####################
	# 环境变量填充
	cat $MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard.stop.template |
		awk '$0 !~ /^\s*#.*$/' |
		sed 's/[ "]/\\&/g' |
		while read -r line; do
			eval echo ${line}
		done >$MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.stop
	done
done 

#######################scp########################
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arr=($MONGOS)
IFS="$OLD_IFS"
for s in ${arr[@]}
do
	echo -e  "\033[1m 分发 修改后的 mongo install  all script at $s \033[0m"
	scp -r $MONGO_PACKAGE_PATH "$s":$TD_BASE
done

#######################start shard########################
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arrs=($MONGOS)
IFS="$OLD_IFS"
for((i=0;i<$TD_MDB_SHARD_GROUD_NUM;i++));do
	for s1 in "${!arrs[@]}"; do
		ssh "${arrs[$s1]}" "chmod +x $MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.run"
		ssh  "${arrs[$s1]}" "$MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.run"
	done
done

sleep 5s 
$MONGO_PACKAGE_PATH/systemctls/init/2-initRS.sh

sleep 2s 

$MONGO_PACKAGE_PATH/systemctls/init/3-initShardCluster.sh

sleep 3s

$MONGO_PACKAGE_PATH/systemctls/init/4-initConllection.sh

echo -e "\033[1m Mongo Install Success  \033[0m"




