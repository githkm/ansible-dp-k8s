##### 1、安装基础环境（准备好至少三台主机作为master，如果添加node节点再增加..）

```
yum -y install epel-release
yum install git vim sshpass python-devel python-pip -y
pip install --upgrade pip -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
pip install ansible netaddr -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
git clone https://git.boleme.net/ops-group/ansible.git
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
[etcd]
192.168.96.19 NODE_NAME=192.168.96.19-name-1
192.168.96.18 NODE_NAME=192.168.96.18-name-2
192.168.96.20 NODE_NAME=192.168.96.20-name-3

[etcd:vars]
ansible_ssh_user=root
ansible_ssh_pass=Zt81726354.


[keepalived]
192.168.96.19   type=MASTER priority=100
192.168.96.18   type=BACKUP priority=99
192.168.96.20   type=BACKUP priority=98

[keepalived:vars]
vip=192.168.83.83
ansible_ssh_user=root
ansible_ssh_pass=Zt81726354.

[kube-master]
192.168.96.19
192.168.96.18
192.168.96.20

[kube-master:vars]
ansible_ssh_user=root
ansible_ssh_pass=Zt81726354.

[kube-node]
192.168.96.22
192.168.96.23

[kube-node:vars]
ansible_ssh_user=root
ansible_ssh_pass=Zt81726354.
```

备注：如果每一个账户和密码都不一样可以这样写（密码一样请忽略）

```
[kube-node]
127.0.0.1 ansible_ssh_user=root ansible_ssh_port=22 ansible_ssh_pass=123456
192.168.1.137 NODE_NAME=192.168.1.137 ansible_ssh_user=root ansible_ssh_port=22 ansible_ssh_pass=123456
```
##### 4、创建集群负载均衡api接口（将三台master的6443端口映射集群ip的5443端口）
```
（1）、替换“group_vars/all.yaml”文件中 loadbalancer_apiserver_ip选项ip地址为负载均衡api接口地址。
（2）、”kube_pods_subnet“ “kube_service_addresses” 分别为pods和service网段。
（3）、keepalived_enable: true 修改为：keepalived_enable: false
```
##### 5、安装集群etcd服务
```
ansible-playbook etcd.yaml -i ./inventory/
systemctl status etcd #查看安装状态
```
##### 6、安装K8s
```
ansible-playbook k8s-install.yml -i ./inventory/
kubectl get nodes #查看master安装结果

NAME            STATUS   ROLES    AGE   VERSION
192.168.96.18   NoReady    master   13m   v1.14.6-aliyun.1
192.168.96.19   NoReady    master   13m   v1.14.6-aliyun.1
192.168.96.20   NoReady    master   13m   v1.14.6-aliyun.1
```
##### 7、安装k8s组件
```
ansible-playbook k8s-addons.yml -i ./inventory/  #在安装组件时请记录dashboard 令牌以便登录使用。
kubectl get pods -n kube-system #查看组件安装状态

NAME                                        READY   STATUS    RESTARTS   AGE
coredns-7fd797fcd9-9kt44                    1/1     Running   0          56m
coredns-7fd797fcd9-dbcps                    1/1     Running   0          56m
heapster-567dc5cf87-2gqsd                   1/1     Running   0          55m
kube-apiserver-192.168.96.18                1/1     Running   1          57m
kube-apiserver-192.168.96.19                1/1     Running   2          57m
kube-apiserver-192.168.96.20                1/1     Running   2          55m
kube-controller-manager-192.168.96.18       1/1     Running   0          57m
kube-controller-manager-192.168.96.19       1/1     Running   0          55m
kube-controller-manager-192.168.96.20       1/1     Running   0          57m
kube-flannel-ds-46wql                       2/2     Running   0          44m
kube-flannel-ds-5fzz8                       2/2     Running   0          56m
kube-flannel-ds-hk9mf                       2/2     Running   0          56m
kube-flannel-ds-jlcqg                       2/2     Running   0          45m
kube-flannel-ds-kt5vm                       2/2     Running   0          56m
kube-proxy-master-4pc6x                     1/1     Running   0          57m
kube-proxy-master-brl2j                     1/1     Running   0          56m
kube-proxy-master-rmnfl                     1/1     Running   0          57m
kube-proxy-worker-x9fvn                     1/1     Running   0          44m
kube-proxy-worker-zt7jf                     1/1     Running   0          45m
kube-scheduler-192.168.96.18                1/1     Running   0          56m
kube-scheduler-192.168.96.19                1/1     Running   1          57m
kube-scheduler-192.168.96.20                1/1     Running   0          56m
kubernetes-dashboard-7f8c4f5b44-b72ss       1/1     Running   0          55m
metrics-server-99849dc95-hlpsx              2/2     Running   0          44m
monitoring-influxdb-86db745965-jh5d2        1/1     Running   0          55m
nginx-ingress-controller-589ff75986-4bl22   1/1     Running   0          55m
nginx-ingress-controller-589ff75986-ww2ds   1/1     Running   0          55m
nginx-proxy-192.168.96.18                   1/1     Running   0          57m
nginx-proxy-192.168.96.19                   1/1     Running   0          57m
nginx-proxy-192.168.96.20                   1/1     Running   0          57m
```
##### 8、安装、新增k8s节点

```
（1）首先请确认inventory/hosts文件中node节点中有已经安装好的节点主机ip，如果有请注释，然后在添加新的node节点ip地址和用户密码，如下。

[kube-node]
#192.168.96.22
#192.168.96.23
192.168.96.137 ansible_ssh_user=root ansible_ssh_port=22 ansible_ssh_pass=123456

（2）、复制master集群token值粘贴至group_vars/all.yaml文件中的kubeadm_token 。
kubeadm token list

TOKEN                     TTL       EXPIRES                     USAGES                   DESCRIPTION   EXTRA GROUPS
i3hpnr.v1wt6hiqd15sm1ws   22h       2019-09-10T15:53:32+08:00   authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
odn071.w8gpxnh1w8c2rs3e   22h       2019-09-10T15:53:21+08:00   authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
zrfvt9.m72h00qu7u5qwhwh   22h       2019-09-10T15:53:22+08:00   authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
```
##### 9、安装node节点
```
ansible-playbook k8s-node.yaml -i ./inventory/
```
##### 10、查看安装后的结果
```
kubectl get nodes


NAME            STATUS   ROLES    AGE   VERSION
192.168.96.18   Ready    master   71m   v1.14.6-aliyun.1
192.168.96.19   Ready    master   71m   v1.14.6-aliyun.1
192.168.96.20   Ready    master   71m   v1.14.6-aliyun.1
192.168.96.22   Ready    <none>   59m   v1.14.6-aliyun.1
192.168.96.137  Ready    <none>   58m   v1.14.6-aliyun.1
```
