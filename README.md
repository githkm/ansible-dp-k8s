## 运维安装部署编排脚本
### 安装ansible
> ###### 在控制端机器执行以下命令安装ansible
```
yum -y install python-devel python-pip
pip install ansible netaddr -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
```

### 使用ssh互信的方式管理主机
```
ssh-keygen
scp id_rsa.pub root@192.168.83.41:/root/.ssh/authorized_keys
```

### ansible不配置ssh免密钥,使用密码登录
先安装sshpass组件
```
yum install sshpass -y
```
/etc/ansible/hosts文件中添加用户密码,认证ssh连接
```
[test]
127.0.0.1 ansible_ssh_user=root ansible_ssh_port=22 ansible_ssh_pass=123456
192.168.1.137 ansible_ssh_user=root ansible_ssh_port=22 ansible_ssh_pass=123456
```

#### 报错1 Please add this host's fingerprint to your known_hosts file to manage this host
> ##### vim /etc/ansible/ansible.cfg
```
[defaults]
host_key_checking = False
```
