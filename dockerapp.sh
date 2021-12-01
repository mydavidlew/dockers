#!/bin/bash
APP_DS=ds; APP_MA=ma; APP_MS=ms; APP_ES=es; APP_EB=eb; APP_DE=de; APP_PA=pa
D_MY1=mysql1; D_PG1=postgres1; D_MG1=mongo1; D_RD1=redis1; D_SL1=solr1
D_CE1=container-exporter1; D_NE1=node-exporter1; D_CA1=cadvisor1
D_AM1=alertmanager1; D_PR1=prometheus1; D_GR1=grafana1
D_ES1=elastic1; D_KI1=kibana1; D_LS1=logstash1
D_AB1=auditbeat1; D_FB1=filebeat1; D_HB1=heartbeat1; D_JB1=journalbeat1; D_MB1=metricbeat1; D_PB1=packetbeat1
D_BC1=kie-workbench1; D_KS1=kie-server1
D_PA1=portainer-agent

L_ES1=elasticsearch; L_KI1=kibana; L_LS1=logstash
L_BC1=business-central-workbench; L_KS1=kie-server

SLEEP_INT=1
D_NETWORK=appnet
C_START=start; C_STOP=stop; C_RUN=run; C_REMOVE=rm; C_INIT=init
C_DOCKER01="docker $C_RUN --rm -d"
C_DOCKER02="docker $C_RUN -d"
C_DOCKER=$C_DOCKER02
C_MOUNT="--mount type=bind"
L_PATH="/opt/docker"
C_COMMAND="null"
LABEL_DS="io.portainer.kubernetes.application.stack=datastore"
LABEL_MS="io.portainer.kubernetes.application.stack=monitoring"
LABEL_ES="io.portainer.kubernetes.application.stack=elasticsearch"
LABEL_DE="io.portainer.kubernetes.application.stack=rulengine"
LABEL_PA="io.portainer.kubernetes.application.stack=portainer"

function check_command() {
  if [[ $1 == $C_START || $1 == $C_STOP || $1 == $C_RUN || $1 == $C_REMOVE || $1 == $C_INIT ]] ; then
    echo "$(date) $line $$: valid docker $1 command found"
    C_COMMAND=$1
    if [[ $1 == $C_INIT ]] ; then
      # 1st time run that pull image from public repository
      C_DOCKER=$C_DOCKER01
    fi
  else
    echo "$(date) $line $$: error detected docker $1 command"
  fi
}

function check_network() { 
  if [[ ! "$(docker network ls | grep $D_NETWORK)" ]] ; then
    echo "$(date) $line $$: creating $D_NETWORK bridge network"
    docker network create $D_NETWORK
    sleep $SLEEP_INT
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

function get_netstat() {
  if [[ $1 == $C_START || $1 == $C_RUN ]] ; then
    APPID=$(docker inspect -f '{{.State.Pid}}' $2)
    # echo "$(date) $line $$: $2 container with $APPID id"
    # sudo nsenter -t $APPID -n netstat -aentop
  fi
}

if [[ $# -eq 2 && ($1 == $C_RUN || $1 == $C_INIT) && $2 == $APP_DS ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all datastore services"
  if [[ $1 == $C_INIT ]] ; then
    $C_DOCKER --hostname=$D_MY1.local --name=$D_MY1 --network=$D_NETWORK --label=$LABEL_DS --env "MYSQL_ROOT_PASSWORD=password" -p 3306:3306 mysql:latest
    $C_DOCKER --hostname=$D_PG1.local --name=$D_PG1 --network=$D_NETWORK --label=$LABEL_DS --env "POSTGRES_PASSWORD=password" -p 5432:5432 postgres:latest
    $C_DOCKER --hostname=$D_MG1.local --name=$D_MG1 --network=$D_NETWORK --label=$LABEL_DS --env "MONGO_INITDB_ROOT_USERNAME=root" --env "MONGO_INITDB_ROOT_PASSWORD=password" -p 27017:27017 mongo:latest
    $C_DOCKER --hostname=$D_RD1.local --name=$D_RD1 --network=$D_NETWORK --label=$LABEL_DS -p 6379:6379 redis:latest
    $C_DOCKER --hostname=$D_SL1.local --name=$D_SL1 --network=$D_NETWORK --label=$LABEL_DS -p 8983:8983 solr:latest
    sleep $SLEEP_INT; sleep $SLEEP_INT; sleep $SLEEP_INT; sleep $SLEEP_INT; sleep $SLEEP_INT
    ### $C_MOUNT,src=$L_PATH"/mysql/data",dst=/var/lib/mysql --- sudo chown 999:999 -R mysql/data
    docker exec -w /var/lib/mysql $D_MY1 bash -c 'tar -zcvf /tmp/mysql-data.tgz *'
    docker cp $D_MY1:/tmp/mysql-data.tgz mysql/
    if [ -d "mysql/data" ] ; then
      sudo rm -rf mysql/data/*
    fi
    sudo tar --same-owner -zxvf mysql/mysql-data.tgz --directory mysql/data
    ### $C_MOUNT,src=$L_PATH"/postgres/data",dst=/var/lib/postgresql/data --- sudo chown 999:999 -R postgres/data
    docker exec -w /var/lib/postgresql/data $D_PG1 bash -c 'tar -zcvf /tmp/psql-data.tgz *'
    docker cp $D_PG1:/tmp/psql-data.tgz postgres/
    if [ -d "postgres/data" ] ; then
      sudo rm -rf postgres/data/*
    fi
    sudo tar --same-owner -zxvf postgres/psql-data.tgz --directory postgres/data
    ### $C_MOUNT,src=$L_PATH"/mongo/data",dst=/data/db --- sudo chown 999:999 -R mongo/data
    docker exec -w /data/db $D_MG1 bash -c 'tar -zcvf /tmp/mongo-data.tgz *'
    docker cp $D_MG1:/tmp/mongo-data.tgz mongo/
    if [ -d "mongo/data" ] ; then
      sudo rm -rf mongo/data/*
    fi
    sudo tar --same-owner -zxvf mongo/mongo-data.tgz --directory mongo/data
    ### $C_MOUNT,src=$L_PATH"/redis/data",dst=/data --- sudo chown 999:999 -R redis/data
    docker exec -w /data $D_RD1 bash -c 'tar -zcvf /tmp/redis-data.tgz *'
    docker cp $D_RD1:/tmp/redis-data.tgz redis/
    if [ -d "redis/data" ] ; then
      sudo rm -rf redis/data/*
    fi
    sudo tar --same-owner -zxvf redis/redis-data.tgz --directory redis/data
    ### $C_MOUNT,src=$L_PATH"/solr/data",dst=/var/solr/data --- sudo chown 8983:8983 -R solr/data
    docker exec -w /var/solr/data $D_SL1 bash -c 'tar -zcvf /tmp/solr-data.tgz *'
    docker cp $D_SL1:/tmp/solr-data.tgz solr/
    if [ -d "solr/data" ] ; then
      sudo rm -rf solr/data/*
    fi
    sudo tar --same-owner -zxvf solr/solr-data.tgz --directory solr/data
  else
    $C_DOCKER --hostname=$D_MY1.local --name=$D_MY1 --network=$D_NETWORK --label=$LABEL_DS --env "MYSQL_ROOT_PASSWORD=password" $C_MOUNT,src=$L_PATH"/mysql/data",dst=/var/lib/mysql -p 3306:3306 mysql:latest
    get_netstat $C_COMMAND $D_MY1
    sleep $SLEEP_INT
    $C_DOCKER --hostname=$D_PG1.local --name=$D_PG1 --network=$D_NETWORK --label=$LABEL_DS --env "POSTGRES_PASSWORD=password" $C_MOUNT,src=$L_PATH"/postgres/data",dst=/var/lib/postgresql/data -p 5432:5432 postgres:latest
    get_netstat $C_COMMAND $D_PG1
    sleep $SLEEP_INT
    $C_DOCKER --hostname=$D_MG1.local --name=$D_MG1 --network=$D_NETWORK --label=$LABEL_DS --env "MONGO_INITDB_ROOT_USERNAME=root" --env "MONGO_INITDB_ROOT_PASSWORD=password" $C_MOUNT,src=$L_PATH"/mongo/data",dst=/data/db -p 27017:27017 mongo:latest
    get_netstat $C_COMMAND $D_MG1
    sleep $SLEEP_INT
    $C_DOCKER --hostname=$D_RD1.local --name=$D_RD1 --network=$D_NETWORK --label=$LABEL_DS $C_MOUNT,src=$L_PATH"/redis/data",dst=/data -p 6379:6379 redis:latest
    get_netstat $C_COMMAND $D_RD1
    sleep $SLEEP_INT
    $C_DOCKER --hostname=$D_SL1.local --name=$D_SL1 --network=$D_NETWORK --label=$LABEL_DS $C_MOUNT,src=$L_PATH"/solr/data",dst=/var/solr/data -p 8983:8983 solr:latest
    get_netstat $C_COMMAND $D_SL1
    sleep $SLEEP_INT
  fi
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_DS ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all datastore services"
  docker $C_COMMAND $D_MY1 $D_PG1 $D_MG1 $D_RD1 $D_SL1
  get_netstat $C_COMMAND $D_MY1
  get_netstat $C_COMMAND $D_PG1
  get_netstat $C_COMMAND $D_MG1
  get_netstat $C_COMMAND $D_RD1
  get_netstat $C_COMMAND $D_SL1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 == $C_RUN && $2 == $APP_MA ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all monitor agent services"
  $C_DOCKER --hostname=$D_CE1.local --name=$D_CE1 --network=$D_NETWORK --label=$LABEL_MS $C_MOUNT,src=/var/run/docker.sock,dst=/var/run/docker.sock -p 9104:9104 prom/container-exporter
  get_netstat $C_COMMAND $D_CE1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_NE1.local --name=$D_NE1 --network=$D_NETWORK --label=$LABEL_MS -p 9100:9100 prom/node-exporter
  get_netstat $C_COMMAND $D_NE1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_CA1.local --name=$D_CA1 --network=$D_NETWORK --label=$LABEL_MS $C_MOUNT,src=/,dst=/rootfs $C_MOUNT,src=/var/run,dst=/var/run $C_MOUNT,src=/sys,dst=/sys $C_MOUNT,src=/var/lib/docker/,dst=/var/lib/docker -p 9109:8080 google/cadvisor
  get_netstat $C_COMMAND $D_CA1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_MA ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all monitor agent services"
  docker $C_COMMAND $D_CE1 $D_NE1 $D_CA1
  get_netstat $C_COMMAND $D_CE1
  get_netstat $C_COMMAND $D_NE1
  get_netstat $C_COMMAND $D_CA1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 == $C_RUN && $2 == $APP_MS ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all monitor server services"
  $C_DOCKER --hostname=$D_AM1.local --name=$D_AM1 --network=$D_NETWORK --label=$LABEL_MS $C_MOUNT,src=$L_PATH"/alertmanager/etc/alertmanager.yml",dst=/etc/alertmanager/alertmanager.yml -p 9093:9093 prom/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
  get_netstat $C_COMMAND $D_AM1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_PR1.local --name=$D_PR1 --network=$D_NETWORK --label=$LABEL_MS $C_MOUNT,src=$L_PATH"/prometheus/etc/prometheus.yml",dst=/etc/prometheus/prometheus.yml $C_MOUNT,src=$L_PATH"/prometheus/etc/alert_rules.yml",dst=/etc/prometheus/alert_rules.yml -p 9090:9090 prom/prometheus
  get_netstat $C_COMMAND $D_PR1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_GR1.local --name=$D_GR1 --network=$D_NETWORK --label=$LABEL_MS $C_MOUNT,src=$L_PATH"/grafana/conf/grafana.ini",dst=/etc/grafana/grafana.ini $C_MOUNT,src=$L_PATH"/grafana/data",dst=/var/lib/grafana -p 3000:3000 grafana/grafana
  get_netstat $C_COMMAND $D_GR1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_MS ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all monitor server services"
  docker $C_COMMAND $D_AM1 $D_PR1 $D_GR1
  get_netstat $C_COMMAND $D_AM1
  get_netstat $C_COMMAND $D_PR1
  get_netstat $C_COMMAND $D_GR1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 == $C_RUN && $2 == $APP_ES ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all elastic stack services"
  $C_DOCKER --hostname=$D_ES1.local --name=$D_ES1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/elasticsearch/conf",dst=/usr/share/elasticsearch/config --env "discovery.type=single-node" -p 9200:9200 -p 9300:9300 docker.elastic.co/elasticsearch/elasticsearch:7.12.0
  get_netstat $C_COMMAND $D_ES1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_KI1.local --name=$D_KI1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/kibana/conf",dst=/usr/share/kibana/config --link $D_ES1:$L_ES1 -p 5601:5601 docker.elastic.co/kibana/kibana:7.12.0
  get_netstat $C_COMMAND $D_KI1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_LS1.local --name=$D_LS1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/logstash/conf",dst=/usr/share/logstash/config $C_MOUNT,src=$L_PATH"/logstash/pipeline",dst=/usr/share/logstash/pipeline --link $D_ES1:$L_ES1 -p 5044:5044 -p 9600:9600 docker.elastic.co/logstash/logstash:7.12.0
  get_netstat $C_COMMAND $D_LS1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_ES ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all elastic stack services"
  docker $C_COMMAND $D_ES1 $D_KI1 $D_LS1
  get_netstat $C_COMMAND $D_ES1
  get_netstat $C_COMMAND $D_KI1
  get_netstat $C_COMMAND $D_LS1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 == $C_RUN && $2 == $APP_EB ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all elastic beats services"
  $C_DOCKER --hostname=$D_AB1.local --name=$D_AB1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/allbeats/conf/auditbeat.yml",dst=/usr/share/auditbeat/auditbeat.yml --cap-add="AUDIT_CONTROL" --link $D_ES1:$L_ES1 --link $D_KI1:$L_KI1 --link $D_LS1:$L_LS1 docker.elastic.co/beats/auditbeat:7.12.0
  get_netstat $C_COMMAND $D_AB1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_FB1.local --name=$D_FB1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/allbeats/conf/filebeat.yml",dst=/usr/share/filebeat/filebeat.yml --link $D_ES1:$L_ES1 --link $D_KI1:$L_KI1 --link $D_LS1:$L_LS1 docker.elastic.co/beats/filebeat:7.12.0
  get_netstat $C_COMMAND $D_FB1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_HB1.local --name=$D_HB1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/allbeats/conf/heartbeat.yml",dst=/usr/share/heartbeat/heartbeat.yml --link $D_ES1:$L_ES1 --link $D_KI1:$L_KI1 --link $D_LS1:$L_LS1 docker.elastic.co/beats/heartbeat:7.12.0
  get_netstat $C_COMMAND $D_HB1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_JB1.local --name=$D_JB1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/allbeats/conf/journalbeat.yml",dst=/usr/share/journalbeat/journalbeat.yml --link $D_ES1:$L_ES1 --link $D_KI1:$L_KI1 --link $D_LS1:$L_LS1 docker.elastic.co/beats/journalbeat:7.12.0
  get_netstat $C_COMMAND $D_JB1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_MB1.local --name=$D_MB1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/allbeats/conf/metricbeat.yml",dst=/usr/share/metricbeat/metricbeat.yml --link $D_ES1:$L_ES1 --link $D_KI1:$L_KI1 --link $D_LS1:$L_LS1 docker.elastic.co/beats/metricbeat:7.12.0
  get_netstat $C_COMMAND $D_MB1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_PB1.local --name=$D_PB1 --network=$D_NETWORK --label=$LABEL_ES $C_MOUNT,src=$L_PATH"/allbeats/conf/packetbeat.yml",dst=/usr/share/packetbeat/packetbeat.yml --cap-add=NET_ADMIN --link $D_ES1:$L_ES1 --link $D_KI1:$L_KI1 --link $D_LS1:$L_LS1 docker.elastic.co/beats/packetbeat:7.12.0
  get_netstat $C_COMMAND $D_PB1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_EB ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all elastic beats services"
  docker $C_COMMAND $D_AB1 $D_FB1 $D_HB1 $D_JB1 $D_MB1 $D_PB1
  get_netstat $C_COMMAND $D_AB1
  get_netstat $C_COMMAND $D_FB1
  get_netstat $C_COMMAND $D_HB1
  get_netstat $C_COMMAND $D_JB1
  get_netstat $C_COMMAND $D_MB1
  get_netstat $C_COMMAND $D_PB1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 == $C_RUN && $2 == $APP_DE ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all drools engine services"
  $C_DOCKER --hostname=$D_BC1.local --name=$D_BC1 --network=$D_NETWORK --label=$LABEL_DE --env "KIE_SERVER_PROFILE=standalone-full" --link $D_KS1:$L_KS1 $C_MOUNT,src=$L_PATH"/kie-workbench/conf/mgmt-users.properties",dst=/opt/jboss/wildfly/standalone/configuration/mgmt-users.properties $C_MOUNT,src=$L_PATH"/kie-workbench/conf/mgmt-groups.properties",dst=/opt/jboss/wildfly/standalone/configuration/mgmt-groups.properties $C_MOUNT,src=$L_PATH"/kie-workbench/conf/application-users.properties",dst=/opt/jboss/wildfly/standalone/configuration/application-users.properties $C_MOUNT,src=$L_PATH"/kie-workbench/conf/application-roles.properties",dst=/opt/jboss/wildfly/standalone/configuration/application-roles.properties $C_MOUNT,src=$L_PATH"/kie-workbench/bin/start_business-central-wb.sh",dst=/opt/jboss/wildfly/bin/start_business-central-wb.sh -p 8080:8080 -p 8001:8001 jboss/business-central-workbench:7.29.0.Final
  get_netstat $C_COMMAND $D_BC1
  sleep $SLEEP_INT
  $C_DOCKER --hostname=$D_KS1.local --name=$D_KS1 --network=$D_NETWORK --label=$LABEL_DE --env "KIE_SERVER_PROFILE=standalone-full" --link $D_BC1:$L_BC1 $C_MOUNT,src=$L_PATH"/kie-server/conf/mgmt-users.properties",dst=/opt/jboss/wildfly/standalone/configuration/mgmt-users.properties $C_MOUNT,src=$L_PATH"/kie-server/conf/mgmt-groups.properties",dst=/opt/jboss/wildfly/standalone/configuration/mgmt-groups.properties $C_MOUNT,src=$L_PATH"/kie-server/conf/application-users.properties",dst=/opt/jboss/wildfly/standalone/configuration/application-users.properties $C_MOUNT,src=$L_PATH"/kie-server/conf/application-roles.properties",dst=/opt/jboss/wildfly/standalone/configuration/application-roles.properties $C_MOUNT,src=$L_PATH"/kie-server/bin/start_kie-wb.sh",dst=/opt/jboss/wildfly/bin/start_kie-wb.sh -p 8081:8080 jboss/kie-server:7.29.0.Final
  get_netstat $C_COMMAND $D_KS1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_DE ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all drools engine services"
  docker $C_COMMAND $D_BC1 $D_KS1
  get_netstat $C_COMMAND $D_BC1
  get_netstat $C_COMMAND $D_KS1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 == $C_RUN && $2 == $APP_PA ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all Portainer Agent services"
##$C_DOCKER --hostname=$D_PA1.local --name=$D_PA1 --network=$D_NETWORK --label=$LABEL_PA -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes -p 9001:9001 portainer/agent:latest
  $C_DOCKER --name=$D_PA1 --network=$D_NETWORK --label=$LABEL_PA -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes -p 9001:9001 portainer/agent:latest
  get_netstat $C_COMMAND $D_PA1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_PA ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all Portainer Agent services"
  docker $C_COMMAND $D_PA1
  get_netstat $C_COMMAND $D_PA1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 == $C_RUN && $2 == $APP_XX ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all XXX services"
  $C_DOCKER --hostname=$D_XX1.local --name=$D_XX1 --network=$D_NETWORK --label=$LABEL_XX1 $C_MOUNT,src=$L_PATH"/null",dst=/null -p 0000:0000 null
  get_netstat $C_COMMAND $D_XX1
  sleep $SLEEP_INT
elif [[ $# -eq 2 && $1 != $C_RUN && $2 == $APP_XX ]] ; then
  check_network
  check_command $1
  echo "$(date) $line $$: $C_COMMAND all XXX services"
  docker $C_COMMAND $D_XX1
  get_netstat $C_COMMAND $D_XX1
  sleep $SLEEP_INT
else
  echo "$(date) $line $$: Wrong party! pls use '$0 <$C_START/$C_STOP/$C_RUN/$C_REMOVE/$C_INIT> <$APP_DS/$APP_MA/$APP_MS/$APP_ES/$APP_EB/$APP_DE/$APP_PA>'"
fi
# show the docker containers and systems
check_docker
# end
