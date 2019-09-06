- name: "Master开启审计"
  shell: "cp -rf /opt/pkg/kubernetes/{{ kubernetes_version }}/module/audit-policy.yml /etc/kubernetes/audit-policy.yml"
- name: "配置nginx代理配置文件"
  template:
    src: "nginx.conf.j2"
    dest: "{{ nginx_config_dir }}/nginx.conf"
    owner: root
    mode: 0755
    backup: yes
- name: "校验nginx配置"
  stat:
    path: "{{ nginx_config_dir }}/nginx.conf"
  register: nginx_stat
- name: "nginx代理容器"
  template:
    src: nginx-proxy.manifest.j2
    dest: "/etc/kubernetes/manifests/nginx-proxy.yml"
- name: "创建ETCD证书目录"
  file:
    path: "{{ item }}"
    state: directory
  with_items:
    - "/etc/kubernetes/pki/etcd"
- name: "复制ETCD证书"
  shell: "cp -rf {{ etcd_data_dir }}/cert/*  /etc/kubernetes/pki/etcd/"
- name: Check if kubeadm has already run
  stat:
    path: "/etc/kubernetes/pki/ca.key"
  register: kubeadm_ca
- name: generate k8s certs
  include: gen-master-certs.yml
- name: Create kubeadm token for joining nodes with 24h expiration (default)
  command: "kubeadm token generate"
  register: temp_token
  retries: 5
  delay: 5
  until: temp_token is succeeded
  delegate_to: "{{ groups['kube-master'] | first }}"
  when: kubeadm_token is not defined
- name: Set kubeadm_token
  set_fact:
    kubeadm_token: "{{ temp_token.stdout }}"
  when: temp_token.stdout is defined
  tags:
    - kubeadm_token
- name: "创建kubeadm配置"
  template:
    src: kubeadm.cfg.j2
    dest: /etc/kubeadm/kubeadm.cfg
- name: "初始化集群Init"
  shell: 'kubeadm init --config /etc/kubeadm/kubeadm.cfg'
- name: "拷贝admin.conf配置"
  shell: "{{ item }}"
  with_items:
    - 'mkdir -p $HOME/.kube'
    - 'cp -i /etc/kubernetes/admin.conf $HOME/.kube/config'
    - 'chown $(id -u):$(id -g) $HOME/.kube/config'
- name: "生成kube-proxy"
  template:
    src: kube-proxy.yml.j2
    dest: /etc/kubernetes/kube-proxy.yml
- name: "创建kube-proxy"
  command: "kubectl apply -f /etc/kubernetes/kube-proxy.yml -n kube-system"
  when: inventory_hostname == groups['kube-master'][0]
- name: "调整apiserver配置"
  shell: >
    cd /etc/kubernetes/manifests &&
    sed -i "/- kube-controller-manager/a\ \ \ \ - --experimental-cluster-signing-duration=87600h0m0s" kube-controller-manager.yaml &&
    sed -i "/- kube-apiserver/a\ \ \ \ - --profiling=false" kube-apiserver.yaml &&
    sed -i "/- kube-apiserver/a\ \ \ \ - --runtime-config=admissionregistration.k8s.io/v1alpha1" kube-apiserver.yaml &&
    sed -i "/- kube-apiserver/a\ \ \ \ - --enable-aggregator-routing=true" kube-apiserver.yaml &&
    sed -i "/- kube-apiserver/a\ \ \ \ - --endpoint-reconciler-type=lease" kube-apiserver.yaml &&
    sed -i "/- kube-apiserver/a \    - --apiserver-count=500" kube-apiserver.yaml &&
    sed -i "s/NodeRestriction/NodeRestriction,Initializers/g" kube-apiserver.yaml &&
    sed -i "/- kube-apiserver/a \    - --audit-policy-file=/etc/kubernetes/audit-policy.yml" kube-apiserver.yaml &&
    sed -i "/- kube-apiserver/a \    - --audit-log-path=/var/log/kubernetes/kubernetes.audit\n    - --audit-log-maxage=7" kube-apiserver.yaml &&
    sed -i "/- kube-apiserver/a \    - --audit-log-maxbackup=10\n    - --audit-log-maxsize=100" kube-apiserver.yaml &&
    sed -i "/  volumeMounts:/a \    - mountPath: /etc/kubernetes/audit-policy.yml\n      name: audit-policy\n      readOnly: true" kube-apiserver.yaml &&
    sed -i "/  volumes:/a \  - hostPath:\n      path: /etc/kubernetes/audit-policy.yml\n      type: FileOrCreate\n    name: audit-policy" kube-apiserver.yaml &&
    sed -i "/  volumeMounts:/a \    - mountPath: /var/log/kubernetes\n      name: k8s-audit" kube-apiserver.yaml &&
    sed -i "/  volumes:/a \  - hostPath:\n      path: /var/log/kubernetes\n      type: DirectoryOrCreate\n    name: k8s-audit" kube-apiserver.yaml &&
    systemctl restart kubelet

