#!/bin/sh
#
# Once you have docker running you can create a cluster with:
echo 1 Deploy Cluster thru KinD...
kind create cluster --config kubernetes/kind-cluster.yaml
echo
#
# The Dashboard UI is not deployed by default. To deploy it, run the following command:
echo 2 Deploy Dashboard UI...
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
echo
#
# Creating a Service Account. We are creating Service Account with name "admin-user" in namespace "kubernetes-dashboard" first.
echo 3 Create admin-user account...
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
echo
#
# Creating a ClusterRoleBinding. In most cases after provisioning cluster using "kops", "kubeadm" or any other popular tool, the "ClusterRole" "cluster-admin" already exists in the cluster. We can use it and create only "ClusterRoleBinding" for our "ServiceAccount". If it does not exist then you need to create this role first and grant required privileges manually.
echo 4 Create user ServiceAccount...
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
echo
#
# Getting a Bearer Token - Now we need to find token we can use to log in. Execute following command:
echo 5 Create the Authorization Token...
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" > kubernetes/kubeui-token.txt
echo
#
# Create a Metal Load Balancer in kuberbetes network using mode ipvs and strictARP true. Execute following command:
echo 6 Create the MetalLB...
kubectl apply -f kubernetes/metallb-config.yaml
kubectl apply -f kubernetes/metallb-configmap.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
echo
#
# Create a custom own namespace. Execute following command:
echo 7 Create the 'myspace' Namespace...
kubectl create namespace myspace
kubectl config set-context --current --namespace=myspace
echo
#
# Accessing the Dashboard UI - To protect your cluster data, Dashboard deploys with a minimal RBAC configuration by default. Currently, Dashboard only supports logging in with a Bearer Token. Now copy the token and paste it into Enter token field on the login screen at below url. Click "Sign in" button and that's it. You are now logged in as an admin.
echo 8 Done successful...
echo
kubectl proxy
# end