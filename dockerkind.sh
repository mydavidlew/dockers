#!/bin/bash
APP_DASHBOARD=dashboard; APP_PORTAINER=portainer; APP_INGRESS=ingress
C_START=start; C_STOP=stop
C_COMMAND="null"
D_NETWORK=appnet
SLEEP_INT=5

function check_command() {
  if [[ $1 == $C_START || $1 == $C_STOP ]] ; then
    echo "$(date) $line $$: valid kubernetes $1 command found"
    C_COMMAND=$1
  else
    echo "$(date) $line $$: error detected kubernetes $1 command"
  fi
}

function check_network() { 
  if [[ ! "$(docker network ls | grep $D_NETWORK)" ]] ; then
    echo "$(date) $line $$: creating $D_NETWORK bridge network"
    docker network create $D_NETWORK
  else
    echo "$(date) $line $$: $D_NETWORK bridge network exists"
  fi
}

function check_docker() {
  echo "$(date) $line $$: list of container, storage and network"
  docker ps -a
  docker system df
  docker network ls
}

function set_ServiceAccount() {
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
}

function set_ClusterRoleBinding() {
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
}

function set_StorageClass() {
  cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
}

if [[ $# -eq 1 && $1 == $C_START ]] ; then
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all kubernetes services"
  # Once you have docker running you can create a cluster with:
  echo "$(date) $line $$: 1 Create and Deploy Cluster thru KinD - https://kind.sigs.k8s.io/docs/user/configuration/"
  kind create cluster --config kubernetes/kind-cluster.yaml
  sleep $SLEEP_INT; echo
  #
  # Create a KinD Ingress Controller in kuberbetes network. Execute following command:
  echo "$(date) $line $$: 2 Create the Ingress Ambassador/Contour/[NGINX] Controller - https://kind.sigs.k8s.io/docs/user/ingress/#ingress-nginx"
  ###kubectl apply -f kubernetes/ingress-config.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
  sleep $SLEEP_INT; echo
  #
  # Create a Metal Load Balancer in kuberbetes network using mode ipvs and strictARP true. Execute following command:
  echo "$(date) $line $$: 3 Create the MetalLB - https://kind.sigs.k8s.io/docs/user/loadbalancer/ & https://metallb.universe.tf/installation/"
  #-A-#
  ###kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
  #kubectl apply -f kubernetes/metallb-namespace.yaml
  ###kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
  #kubectl apply -f kubernetes/metallb-config.yaml
  ###kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml
  #kubectl apply -f kubernetes/metallb-configmap.yaml
  #-B-#
  ###kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
  kubectl apply -f kubernetes/metallb-native.yaml
  #a#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-frr.yaml
  kubectl apply -f kubernetes/metallb-frr.yaml
  #b#kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-frr-k8s.yaml
  kubectl apply -f kubernetes/metallb-frr-k8s.yaml
  #---#
  kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
  kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl diff -f - -n kube-system
  kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system
  docker network inspect -f '{{.IPAM.Config}}' kind
  sleep $SLEEP_INT; echo
  #
  # Create a Metric Server in kuberbetes for resource monitoring. Execute following command:
  echo "$(date) $line $$: 4 Create the Metric Server - https://github.com/kubernetes-sigs/metrics-server"
  # Latest Metrics Server release can be installed by running:
  ###kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  # Latest Metrics Server release can be installed in high availability mode by running:
  ###kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml
  # Kubelet certificate needs to be signed by cluster Certificate Authority (or disable certificate validation by passing --kubelet-insecure-tls to Metrics Server)
  # Try adding "--kubelet-insecure-tls" using "kubectl edit deploy metrics-server -n kube-system" at the "kind: Deployment->spec->template->spec->containers->args" section.
  kubectl apply -f kubernetes/metric-config.yaml
  sleep $SLEEP_INT; echo
  #
  # Create a custom own namespace. Execute following command:
  echo "$(date) $line $$: 5 Create the 'myspace' Namespace..."
  kubectl create namespace myspace
  kubectl config set-context --current --namespace=myspace
  set_StorageClass # create a local storage
  sleep $SLEEP_INT; echo
  #
  # Display the cluster information. Execute following command:
  echo "$(date) $line $$: 6 Cluster startup successful..."
  kubectl cluster-info --context kind-kind
elif [[ $# -eq 2 && $1 == $C_START && $2 == $APP_DASHBOARD ]] ; then
  # The Dashboard UI is not deployed by default. To deploy it, run the following command:
  echo "$(date) $line $$: 1 Deploy Dashboard UI - https://github.com/kubernetes/dashboard#kubernetes-dashboard"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
  sleep $SLEEP_INT; echo
  #
  # Creating a Service Account. We are creating Service Account with name "admin-user" in namespace "kubernetes-dashboard" first.
  echo "$(date) $line $$: 2 Create admin-user account..."
  set_ServiceAccount
  echo
  #
  # Creating a ClusterRoleBinding. In most cases after provisioning cluster using "kops", "kubeadm" or any other popular tool, the "ClusterRole" "cluster-admin" already exists in the cluster. We can use it and create only "ClusterRoleBinding" for our "ServiceAccount". If it does not exist then you need to create this role first and grant required privileges manually.
  echo "$(date) $line $$: 3 Create user ServiceAccount..."
  set_ClusterRoleBinding
  echo
  #
  # Getting a Bearer Token - Now we need to find token we can use to log in. Execute following command:
  echo "$(date) $line $$: 4 Create the Authorization Token..."
  kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" > kubernetes/kubeui-token.txt
  echo "Token in kubernetes/kubeui-token.txt file"
  echo
  #
  # Accessing the Dashboard UI - To protect your cluster data, Dashboard deploys with a minimal RBAC configuration by default. Currently, Dashboard only supports logging in with a Bearer Token. Now copy the token and paste it into Enter token field on the login screen at below url. Click "Sign in" button and that's it. You are now logged in as an admin.
  echo "$(date) $line $$: 5 Done successful..."
  echo "Dashboard at http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
  kubectl proxy
elif [[ $# -eq 2 && $1 == $C_STOP && $2 == $APP_DASHBOARD ]] ; then
  # The Dashboard UI is not deployed by default. To delete it, run the following command:
  echo "$(date) $line $$: 1 Delete Dashboard UI - https://github.com/kubernetes/dashboard#kubernetes-dashboard"
  kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
elif [[ $# -eq 2 && $1 == $C_START && $2 == $APP_PORTAINER ]] ; then
  # The Portainer Community Edition is not deployed by default. To deploy it, run the following command:
  echo "$(date) $line $$: 1 Deploy Portainer Community - https://docs.portainer.io/v/ce-2.9/start/install/server/kubernetes"
  # To expose via NodePort, you can use the following command (Portainer will be available on port 30777 for HTTP [http://localhost:30777/] and 30779 for HTTPS [https://localhost:30779/]):
  ###kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer.yaml
  # To expose via Load Balancer, this command will provision Portainer at an assigned Load Balancer IP on port 9000 for HTTP [http://<loadbalancer_IP>:9000/] and 9443 for HTTPS [https://<loadbalancer_IP>:9443/]:
  ###kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb.yaml
  kubectl apply -f kubernetes/portainer-config.yaml
  sleep $SLEEP_INT; echo # create a linux portainer agent - https://docs.portainer.io/v/ce-2.9/start/install/agent/docker/linux
  #
  # To explicitly set the target node when deploying using YAML manifests, run the following one-liner to "patch" the deployment, forcing the pod to always be scheduled on the node it's currently running on:
  # ---No need to run this patch---
## kubectl patch deployments -n portainer portainer -p '{"spec": {"template": {"spec": {"nodeSelector": {"kubernetes.io/hostname": "'$(kubectl get pods -n portainer -o jsonpath='{ ..nodeName }')'"}}}}}' || (echo Failed to identify current node of portainer pod; exit 1)
## echo
  #
  # Accessing the Portainer UI - To protect your cluster data, Portainer deploys with a minimal RBAC configuration by default. Click "Sign in" button and that's it. You are now logged in as an admin.
  echo "$(date) $line $$: 2 Done successful..."
  # Run the Portainer expose command using "kubectl port-forward -n portainer deployment/portainer 9000:9000"
  while [[ true ]]; do
    echo -e "*\c"; sleep 1
    cmd=$(kubectl get pods -n portainer -o json | jq '.items[].status.containerStatuses[] | select(.started == true) | {state}' | jq '.state.running.startedAt')
    if [[ ! -z $cmd ]]; then
      echo -e "\n$cmd Portainer at http://localhost:9000/#!/home"
      kubectl port-forward -n portainer deployment/portainer 9000:9000 #--address localhost,0.0.0.0
      break
    fi
  done
elif [[ $# -eq 2 && $1 == $C_STOP && $2 == $APP_PORTAINER ]] ; then
  # The Portainer Community Edition is not deployed by default. To delete it, run the following command:
  echo "$(date) $line $$: 1 Delete Portainer Community - https://docs.portainer.io/v/ce-2.9/start/install/server/kubernetes"
  # To expose via NodePort, you can use the following command (Portainer will be available on port 30777 for HTTP [http://localhost:30777/] and 30779 for HTTPS [https://localhost:30779/]):
  ###kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer.yaml
  # To expose via Load Balancer, this command will provision Portainer at an assigned Load Balancer IP on port 9000 for HTTP [http://<loadbalancer_IP>:9000/] and 9443 for HTTPS [https://<loadbalancer_IP>:9443/]:
  ###kubectl apply -n portainer -f https://raw.githubusercontent.com/portainer/k8s/master/deploy/manifests/portainer/portainer-lb.yaml
  kubectl delete -f kubernetes/portainer-config.yaml
elif [[ $# -eq 2 && $1 == $C_START && $2 == $APP_INGRESS ]] ; then
  echo "$(date) $line $$: 1 Create the Ingress Controller - https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal"
  # Bare-metal (Using NodePort)
  ###kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.3/deploy/static/provider/baremetal/deploy.yaml
  # Docker Desktop
  ###kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.3/deploy/static/provider/cloud/deploy.yaml
  echo "Skipping..."
elif [[ $# -eq 1 && $1 == $C_STOP ]] ; then
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all kubernetes services"
  kind delete cluster
else
  echo "$(date) $line $$: You have gone to the wrong party! use '$0 $C_START/$C_STOP $APP_DASHBOARD/$APP_PORTAINER/$APP_INGRESS'"
fi
# end
