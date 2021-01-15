##### 1、安装基础环境（准备好至少三台主机作为master，如果添加node节点再增加..）

```
yum install git vim -y
git clone https://git.boleme.net/ops-group/ansible.git
yum -y install python-devel python-pip
pip install ansible netaddr -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
```
##### 2、vim /etc/ansible/ansible.cfg (创建文件前先“mkdir -p /etc/ansible”)
```
mkdir -p /etc/ansible
```
```
[defaults]
host_key_checking = False
```
##### 3、通过免密登录或者密码登录管理需要安装的主机（以下方法选其一）
（1）通过ssh免密登录【二选一】
```
ssh-keygen
scp id_rsa.pub root@192.168.83.41:/root/.ssh/authorized_keys
```
（2）通过密码登录方式【二选一】
```
yum install sshpass -y #安装sshpass组件
```
修改和替换ansible/inventory文件夹下面的host文件，包括ip地址，用户名，密码，端口详细如下：
```
[zookeeper]
172.31.161.218 myid=0
172.31.161.63 myid=1
172.31.161.193 myid=2

[zookeeper:vars]
ansible_ssh_user=root
ansible_ssh_pass=123abcABC

[clickhouse:children]
clickhouse-shard1
clickhouse-shard2
clickhouse-shard3

[clickhouse-shard1]
172.31.161.218 shard=1 replica=1

[clickhouse-shard2]
172.31.161.63 shard=2 replica=1

[clickhouse-shard3]
172.31.161.193 shard=3 replica=1

[clickhouse:children:vars]
ansible_ssh_user=root
ansible_ssh_pass=123abcABC
```

备注：如果每一个账户和密码都不一样可以这样写（密码一样请忽略）

##### 4、安装集群zookeeper服务
```
ansible-playbook zookeeper.yaml -i ./inventory/
```

##### 5、安装集群clickhouse服务
```
ansible-playbook clickhouse.yml -i ./inventory/
```
