source MONGO_PACKAGE_PATH/env/env.sh
#!/bin/bash
$MONGO_HOME/bin/mongo mongo_host1:27018 <<EOF
config={
    _id:"configs",
    configsvr:true,
    members:[
        {_id:0,host:"mongo_host1:27018",priority:2},
        {_id:1,host:"mongo_host2:27018"},
        {_id:2,host:"mongo_host3:27018"}],
    settings:{getLastErrorDefaults:{w:"majority",wtimeout:5000}}
};
rs.initiate(config);
exit;
EOF
