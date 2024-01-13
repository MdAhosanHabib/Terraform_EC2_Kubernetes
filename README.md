![EC2_Terraform_Kubernetes](https://github.com/MdAhosanHabib/Terraform_EC2_Kubernetes/assets/43145662/2c072947-64e9-4e08-bdbb-2318db08dfef)

# AWS infrastructure with Terraform and Kubernetes Sample deployment with Layer 7 LB.

This document outlines the steps involved in setting up a Kubernetes cluster on AWS and deploying sample applications with a layer 7 load balancer.

## Prerequisites:
AWS account with access to create EC2 instances

Terraform installed

SSH client (e.g., MobaXterm)

## Steps:

## 1.Create EC2 instances using Terraform:

Navigate to the terraform directory.

Run terraform init to initialize Terraform.

Run terraform plan to view the infrastructure plan.

Run terraform apply to create the EC2 instances.

Note the public and private IP addresses of the instances.

```bash
# sudo yum install -y yum-utils
# sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
# sudo yum -y install terraform

# cd /terraform
# vi main.tf
```
Now paste the main.tf code from this GitHub link:
https://github.com/MdAhosanHabib/Terraform_EC2_Kubernetes/blob/main/main.tf

```bash
# terraform init
# terraform plan
var.key_name
  Name of the SSH key pair
  Enter a value: ahosan_aws.pem

# terraform apply
var.key_name
  Name of the SSH key pair
  Enter a value: ahosan_aws.pem

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
  Enter a value: yes

  Apply complete! Resources: 12 added, 0 changed, 0 destroyed.
  Outputs:
  instance_with_http_access_public_ip = "44.203.87.22"
  private_ips = [
    "10.0.1.207",
    "10.0.1.193",
    "10.0.1.199",
    "10.0.1.16",
  ]
  public_ips = [
    "44.203.87.22",
    "44.203.55.226",
    "3.86.194.237",
    "44.201.240.124",
  ]

# terraform output public_ips
# terraform output private_ips
# terraform output instance_with_http_access_public_ip
```

Now we can connect from mobaxterm by "ahosan_aws.pem" file.

[N.B: Be careful] if we want to destroy infra.
```bash
# terraform destroy
```

## 2.Connect to EC2 instances using SSH:

Use your SSH client to connect to the master node using its public IP address and the provided SSH key.
```bash
# chmod 400 ahosan_aws.pem
# ssh -i /terraform/ahosan_aws.pem ec2-user@44.201.240.124
```

<img width="784" alt="ec2_k8s_master" src="https://github.com/MdAhosanHabib/Terraform_EC2_Kubernetes/assets/43145662/2b872e6a-2761-4759-92ae-04b1497b810f">


## 3.Set up Kubernetes cluster:
### On the master node:

  Disable SELinux and firewalld.
  
  Install Docker and containerd.
  
  Configure Kubernetes repositories and install kubelet, kubeadm, and kubectl.
  
  Initialize the Kubernetes cluster using kubeadm init.
  
  Configure kubectl for the cluster.
  
  Install Calico networking.
  
  Verify cluster status using kubectl get nodes.

### On worker nodes:

  Join the cluster using kubeadm join with the token and hash from the master node.
  
  Verify worker status on the master node using kubectl get nodes.

```bash
### Apply on Master and Worker
# sudo su
# vi /etc/selinux/config
SELINUX=disable

# systemctl stop firewalld.service
# systemctl disable firewalld.service

swapoff -a
sysctl --system

# vi /etc/hosts
10.0.1.193 master1.k8s
10.0.1.199 worker1.k8s
10.0.1.16 worker2.k8s
10.0.1.207 nginx.k8s

# cat /etc/hosts
-- now set hostname in each host as per their name
# hostnamectl set-hostname nginx.k8s
# hostnamectl set-hostname master1.k8s
# hostnamectl set-hostname worker1.k8s
# hostnamectl set-hostname worker2.k8s

# dnf -y upgrade
# dnf -y update
# init 6

# modprobe br_netfilter

# vi /etc/sysctl.d/k8s.conf
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1

# dnf remove containerd.io

# yum update -y
# yum install docker -y

# systemctl start docker
# systemctl enable docker

# echo '{
  "exec-opts": ["native.cgroupdriver=systemd"]
}' > /etc/docker/daemon.json

# containerd config default | sudo tee /etc/containerd/config.toml | grep SystemdCgroup

# vi /etc/containerd/config.toml
# SystemdCgroup = true

# sudo systemctl restart containerd

# cat /etc/containerd/config.toml | grep SystemdCgroup
# systemctl restart docker
# docker version
# docker images

# vi /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni

# dnf upgrade -y
# dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# systemctl enable kubelet
# systemctl start kubelet
# systemctl status kubelet

### on master node
[root@master1 ec2-user]# kubeadm init

# mkdir -p $HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# sudo chown $(id -u):$(id -g) $HOME/.kube/config

# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

[root@master1 ~]# kubectl get pods -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-7ddc4f45bc-rmrfr   1/1     Running   0          39m
kube-system   calico-node-7w7gt                          1/1     Running   0          39m
kube-system   coredns-5dd5756b68-7jgkh                   1/1     Running   0          45m
kube-system   coredns-5dd5756b68-gl6kg                   1/1     Running   0          45m
kube-system   etcd-master1.k8s                           1/1     Running   0          45m
kube-system   kube-apiserver-master1.k8s                 1/1     Running   0          45m
kube-system   kube-controller-manager-master1.k8s        1/1     Running   0          45m
kube-system   kube-proxy-c4x98                           1/1     Running   0          45m
kube-system   kube-scheduler-master1.k8s                 1/1     Running   0          45m
[root@master1 ~]#

### after wait and see ready
[root@master1 ~]# kubectl get nodes
NAME           STATUS   ROLES           AGE   VERSION
master1.kube   Ready    control-plane   57m   v1.28.1
[root@master1 ~]#


#### on worker 1,2
# kubeadm join 10.0.1.193:6443 --token 7fidl8.3lf86gt0uhz2be5w \
        --discovery-token-ca-cert-hash sha256:fcc0389b2203e1eb489097fd236442ef81403a08c8e4f0e6b64c0fa944512606

# systemctl status kubelet

### on master node1
[root@master1 ~]# kubectl get nodes
NAME          STATUS   ROLES           AGE   VERSION
master1.k8s   Ready    control-plane   84m   v1.28.2
worker1.k8s   Ready    <none>          28m   v1.28.2
worker2.k8s   Ready    <none>          27m   v1.28.2
worker3.k8s   Ready    <none>          27m   v1.28.2
[root@master1 ~]#
```

## 4.Deploy sample applications:

### On the master node:
Create a deployment for the FastAPI application (fastapi-deployment.yaml).

Create a NodePort service for the FastAPI application (fastapi-service.yaml).

Create a deployment for the Nginx application (fr-deployment.yaml).

Create a NodePort service for the Nginx application (fr-service.yaml).

Apply the YAML files using kubectl apply -f.

Verify deployment and service status using kubectl get pods and kubectl get svc.

```bash
[root@master1 ec2-user]# cd /home/ec2-user
[root@master1 ec2-user]# vi fastapi-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fastapi
  template:
    metadata:
      labels:
        app: fastapi
    spec:
      containers:
      - name: fastapi
        image: ahosan/ahosantest1:FastAPIv1
        ports:
        - containerPort: 80

[root@master1 ec2-user]# kubectl apply -f fastapi-deployment.yaml
[root@master1 ec2-user]# kubectl get pod

[root@master1 app]# vi fastapi-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-poridhi-io-service
spec:
  selector:
    app: fastapi
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort
[root@master1 ec2-user]# kubectl apply -f fastapi-service.yaml

[root@master1 ec2-user]# vi fr-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
[root@master1 app]# kubectl apply -f fr-deployment.yaml

[root@master1 app]# vi fr-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: fr-poridhi-io-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort
[root@master1 app]# kubectl apply -f fr-service.yaml

[root@master1 ec2-user]# kubectl get svc
NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
api-poridhi-io-service   NodePort    10.105.142.122   <none>        80:30711/TCP   10m
fr-poridhi-io-service    NodePort    10.105.142.122   <none>        80:30712/TCP   10m
kubernetes               ClusterIP   10.96.0.1        <none>        443/TCP        86m
[root@master1 ec2-user]#
```

## 5.Set up Nginx load balancer:
### On the nginx node:
Install Nginx.

Configure Nginx as a reverse proxy for the FastAPI and Nginx services (/etc/nginx/nginx.conf).

Restart Nginx.

```bash
[root@nginx ec2-user]# dnf install nginx -y
[root@nginx ec2-user]# systemctl start nginx.service
[root@nginx ec2-user]# systemctl enable nginx.service

[root@nginx ec2-user]# vi /etc/nginx/nginx.conf   #add this content in "http" block
    upstream api_servers {
            server 10.0.1.16:30711;
            server 10.0.1.199:30711;
        }

    upstream fr_servers {
        server 10.0.1.16:30712;
        server 10.0.1.199:30712;
    }

    server {
        listen 80;
        server_name api.poridhi.io;

        location / {
            proxy_pass http://api_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    server {
        listen 80;
        server_name fr.poridhi.io;

        location / {
            proxy_pass http://fr_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

[root@nginx ec2-user]# systemctl restart nginx.service
```

## 6.Access applications:
Add entries for api.poridhi.io and fr.poridhi.io pointing to the nginx node's IP address in your browser machine's hosts file.
```bash
44.203.87.22 api.poridhi.io
44.203.87.22 fr.poridhi.io
```

Access the applications using the following URLs:

http://api.poridhi.io

http://fr.poridhi.io


Thank you from Ahosan Habib.
Medium: 
