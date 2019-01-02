#!/bin/bash


####### 配置环境变量#######

MONGO_PACKAGE_PATH=$(cd `dirname $0`; pwd)
export MONGO_PACKAGE_PATH=$(cd `dirname $0`; pwd)
source $MONGO_PACKAGE_PATH/env/env.sh
ROUTE_SERVER=$(cat $MONGO_PACKAGE_PATH/config | grep ROUTE_SERVER | awk -F "=" '{print$2}')
CONFIG_SERVER=$(cat $MONGO_PACKAGE_PATH/config | grep CONFIG_SERVER | awk -F "=" '{print$2}')
MONGOS=$(cat $MONGO_PACKAGE_PATH/config | grep MONGOS | awk -F "=" '{print$2}')

function autostart(){
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

#######################start shard########################
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arr=($MONGOS)
IFS="$OLD_IFS"
for((i=0;i<$TD_MDB_SHARD_GROUD_NUM;i++));do
	for s1 in "${!arrs[@]}"; do
	     echo -e "\033[1m  start shard ${arrs[$s1]} let $i \033[0m"
		ssh "${arrs[$s1]}" "chmod +x $MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.run"
		ssh  "${arrs[$s1]}" "$MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.run"
	done
done

}
function autostop(){

######### stop config server #########
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arrs=($CONFIG_SERVER)
IFS="$OLD_IFS"
for s1 in "${!arrs[@]}"; do
	echo -e "\033[32m stop ${arrs[$s1]} config server \033[0m"
	ssh "${arrs[$s1]}" $MONGO_PACKAGE_PATH/systemctls/bin/mongodb-cfgserver.service.stop 
done


#########stop route server #########
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arrs=($ROUTE_SERVER)
IFS="$OLD_IFS"
for s1 in "${!arrs[@]}"; do
	echo -e "\033[32m stop ${arrs[$s1]} route server \033[0m"
	ssh "${arrs[$s1]}" $MONGO_PACKAGE_PATH/systemctls/bin/mongodb-router.service.stop 
done

#######################start shard########################
source $MONGO_PACKAGE_PATH/env/env.sh
OLD_IFS="$IFS"
IFS=","
arr=($MONGOS)
IFS="$OLD_IFS"
for((i=0;i<$TD_MDB_SHARD_GROUD_NUM;i++));do
	for s1 in "${!arrs[@]}"; do
	     echo -e "\033[1m  stop shard ${arrs[$s1]} let $i \033[0m"
		ssh "${arrs[$s1]}" "chmod +x $MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.stop"
		ssh  "${arrs[$s1]}" "$MONGO_PACKAGE_PATH/systemctls/bin/mongo-shard-${arrs[$s1]}.stop"
	done
done

}

case $1 in
"autostart")
	autostart
	;;
"autostop")
	autostop
	;;
*)
	echo -e "\033[1m mongo-usage-esay: \n \t  [autostop] \n \t  [autostart] \033[0m" 
	exit 2 # Command to come out of the program with status 1
	;;
esac
exit 0