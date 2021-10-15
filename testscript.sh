#!/bin/sh
#
NODEPORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services nodeport)
NODES=$(kubectl get nodes -o jsonpath='{ $.items[*].status.addresses[?(@.type=="InternalIP")].address }')
for node in $NODES; do curl -s $node:$NODEPORT | grep -i client_address; done

LB_IP=$(kubectl get svc/foobar-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
for _ in {1..10}; do
  curl ${LB_IP}:5678
done

STATE1=$(kubectl get pods -n portainer -o jsonpath='{ $.items.status.containerStatuses.name }')
STATE2=$(kubectl get pods -n portainer -o jsonpath='{ $.items.status.containerStatuses[?(@.name=="portainer")].ready }')

# {
#     "apiVersion": "v1",
#     "items": [
#         {
#             "apiVersion": "v1",
#             "kind": "Pod",
#             "spec": {
#             },
#             "status": {
#                 "containerStatuses": [
#                     {
#                         "containerID": "containerd://82b1ed831a547a3cef2f81e698c5e94a3472dc31e4ffa0a474a53794c3eea703",
#                         "image": "docker.io/portainer/portainer-ce:latest",
#                         "imageID": "docker.io/portainer/portainer-ce@sha256:76ff22486bcd3713631b5f317efcb69e707a122fe96ffcc0589cf2d3e8e6b890",
#                         "name": "portainer",
#                         "ready": true,
#                         "restartCount": 3,
#                         "started": true,
#                         "state": {
#                             "running": {
#                                 "startedAt": "2021-10-15T06:11:14Z"
#                             }
#                         }
#                     }
#                 ],
#                 "hostIP": "172.19.0.5",
#                 "phase": "Running",
#                 "podIP": "10.244.2.4",
#                 "qosClass": "BestEffort",
#                 "startTime": "2021-10-15T05:55:15Z"
#             }
#         }
#     ],
#     "kind": "List",
#     "metadata": {
#         "resourceVersion": "",
#         "selfLink": ""
#     }
# }
#jq '.items[].status.containerStatuses[] | select(.started == "true") | {state}'
#kubectl get pods -n portainer -o json | jq '.items[].status.containerStatuses[] | select(.started == true) | {state}' | jq '.state.running'
#kubectl get pods -n portainer -o json | jq '.items[].status.containerStatuses[] | select(.started == true) | {state}' | jq '.state.running.startedAt'

nx=1; status=$?
## run date command ##
#cmd=$(kubectl get pods -n portainer -o json | jq '.items[].status.containerStatuses[] | select(.started == true) | {state}' | jq '.state.running.startedAt')
#$cmd
## get status ##
#status=$?
while [ $nx -eq 1 ]; do
  sleep 1
  #$cmd
  cmd=$(kubectl get pods -n portainer -o json | jq '.items[].status.containerStatuses[] | select(.started == true) | {state}' | jq '.state.running.startedAt')
  #kubectl get pods -n portainer -o json | jq '.items[].status.containerStatuses[] | select(.started == true) | {state}' | jq '.state.running.startedAt'
  status=$?
  echo "--> $cmd"
  if [ ! -z $cmd ]; then
    #kubectl port-forward -n portainer deployment/portainer 9000:9000
    echo "abc"
    exit
  fi
done