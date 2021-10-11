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
echo "a=$STATE1"