#!/bin/bash
# set ulimit
ulimit -n 655360

export JAVA_HOME=/usr/java/default
export JRE_HOME=/usr/java/default
PATH=$JAVA_HOME/bin:$PATH

# http install  package
#export MONGO_PACKAGE_PATH=$(pwd)

export TD_BASE=/home/temp
export TD_DATA=$TD_BASE/data


# mongodb environment is not required by mongo processes
export MONGO_HOME=$TD_BASE/mongodb
export MONGO_DATA=$TD_DATA/mongo/data
PATH=$MONGO_HOME/bin:$PATH


#################################################################
# MongoDB shards layout scripts.
# Please DO *NOT* change unless you know what you are doing !!!
#################################################################

export TD_MDB_SHARD_PORT_BASE=27018
export TD_MDB_NODE_COUNT=3
export TD_NODE_COUNT=3
export TD_MDB_SHARD_GROUD_NUM=1 # 默认一个组 
export TD_HOSTNAME_PREFIX=mongo_host

declare -A __tdHostShardPortMap=()
for((i=1;i<=TD_MDB_NODE_COUNT;i++));
do
  #echo i=$i
  TDHOSTNAME="$TD_HOSTNAME_PREFIX$i"
  #echo TDHOSTNAME=$TDHOSTNAME
  TDSHARDPORT=`expr $TD_MDB_SHARD_PORT_BASE + $i`
  #echo TDSHARDPORT=$TDSHARDPORT
  __tdHostShardPortMap[$TDHOSTNAME]=$TDSHARDPORT
done

__tdGetMapValue()
{
  echo ${__tdHostShardPortMap[$1]}
}

__tdGetLocalBaseShardPort()
{
  cat /etc/hosts |grep `hostname` | awk '{print$2}'| while read LINE;
  do
    MDB_SHARD_A_PORT=`__tdGetMapValue $LINE`
    #echo MDB_SHARD_A_PORT=$MDB_SHARD_A_PORT
    if [ -n $MDB_SHARD_A_PORT ]; then
      echo $MDB_SHARD_A_PORT
      break
    else
      echo ""
      continue
    fi
  done
}

__tdGIDDefault=0
__tdNearIDDefault=CURR

__tdGetLocalShardPort()
{
  GID=$1
  NearID=$2
  currBASEPORT=$3

  maxBASEPORT=`expr $TD_MDB_SHARD_PORT_BASE + $TD_MDB_NODE_COUNT`
  minBASEPORT=`expr $TD_MDB_SHARD_PORT_BASE + 1`

  prevBASEPORT=`expr $currBASEPORT - 1`
  if [ $prevBASEPORT -lt $minBASEPORT ];then
    prevBASEPORT=$maxBASEPORT
  fi
  nextBASEPORT=`expr $currBASEPORT + 1`
  if [ $nextBASEPORT -gt $maxBASEPORT ];then
    nextBASEPORT=$minBASEPORT
  fi

  case $NearID in

  "CURR")
    port=`expr $currBASEPORT + $TD_MDB_NODE_COUNT \* $GID`
    echo $port
    ;;

  "PREV")
    port=`expr $prevBASEPORT + $TD_MDB_NODE_COUNT \* $GID`
    echo $port
    ;;

  "NEXT")
    port=`expr $nextBASEPORT + $TD_MDB_NODE_COUNT \* $GID`
    echo $port
    ;;

  *)
    echo ""
    ;;
esac
}

tdGetLocalShardPort()
{
    GID=$__tdGIDDefault
    NearID=$__tdNearIDDefault
    if [ -n "$1" ];then
      GID=$1
    fi
    if [ -n "$2" ];then
      NearID=$2
    fi

    currBASEPORT=$(__tdGetLocalBaseShardPort)
    if [ -z "$currBASEPORT" ];then
      echo ""
    else
      if [ -n "`echo "$GID" | sed -n '/^[0-9][0-9]*$/p'`" ];then
        if [ "$GID" -ge $TD_MDB_SHARD_GROUD_NUM ];then
          echo ""
        elif [ "$GID" -lt 0 ];then
          echo ""
        else
          echo $(__tdGetLocalShardPort "$GID" "$NearID" "$currBASEPORT")
        fi
      else
        echo ""
      fi
    fi
}