## Mongo 安装脚本


* 例如5台机器 详情参考`shard_auto.sh`


![](https://zmatsh.b0.upaiyun.com/images/WX20190102-145701@2x.png)

## 前提
 * 需要`互信`
 * 检查`/etc/hosts` 内部是否包含`mongo_host$`
 * 例子

    ```bash
    # IP地址       第一个别名      第二个别名
    45.32.62.29   mongo_host3  host3
    45.32.62.19   mongo_host1  host1
    45.32.62.20   mongo_host2  host2
    ```

## 问题

* `bin/`内的文件在 `https://zmatsh.b0.upaiyun.com/mongo_tar/mongodb.tar.gz`


## 感谢兽兽提供脚本