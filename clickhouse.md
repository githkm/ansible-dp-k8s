##### 1、安装基础环境（准备好至少三台主机作为master，如果添加node节点再增加..）

```
yum install git vim sshpass python-devel python-pip -y
pip install --upgrade pip
pip install ansible netaddr -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
git clone https://git.boleme.net/ops-group/ansible.git
```

##### 2、通过免密登录或者密码登录管理需要安装的主机（以下方法选其一）
（1）通过ssh免密登录【二选一】
```
ssh-keygen
scp id_rsa.pub root@192.168.83.41:/root/.ssh/authorized_keys
```
（2）通过密码登录方式【二选一】

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
172.31.161.218 shard=1 replica=1 ansible_ssh_user=root ansible_ssh_pass=123abcABC
172.31.161.219 shard=1 replica=2 ansible_ssh_user=root ansible_ssh_pass=123abcABC

[clickhouse-shard2]
172.31.161.63 shard=2 replica=1 ansible_ssh_user=root ansible_ssh_pass=123abcABC
172.31.161.64 shard=2 replica=2 ansible_ssh_user=root ansible_ssh_pass=123abcABC

[clickhouse-shard3]
172.31.161.193 shard=3 replica=1 ansible_ssh_user=root ansible_ssh_pass=123abcABC
172.31.161.194 shard=3 replica=2 ansible_ssh_user=root ansible_ssh_pass=123abcABC

[clickhouse:children:vars]
ansible_ssh_user=root
ansible_ssh_pass=123abcABC
```

备注：如果每一个账户和密码都不一样可以这样写（密码一样请忽略）

##### 3、安装集群zookeeper服务
```
ansible-playbook zookeeper.yaml -i ./inventory/
```

##### 4、安装集群clickhouse服务
```
ansible-playbook clickhouse.yml -i ./inventory/
```
