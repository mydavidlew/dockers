#!/bin/bash
SLEEP_INT=1
CMD_START=start; CMD_STOP=stop; CMD_START_MON=start-monitor; CMD_STOP_MON=stop-monitor
D_NETWORK=appnet
D_MYSQL=mysql1; D_POSTGRES=postgres1; D_MONGO=mongo1; D_REDIS=redis1; D_SOLR=solr1
D_ALERT=alertmanager1; D_CONTAINER=container-exporter1; D_NODE=node-exporter1; D_ADVISOR=cadvisor1; D_PROMETHEUS=prometheus1; D_GRAFANA=grafana1

check_network() { 
    if [ ! "$(docker network ls | grep $D_NETWORK)" ] ; then
        echo "$(date) $line $$: creating $D_NETWORK bridge network"
        docker network create $D_NETWORK
        sleep $SLEEP_INT
    else
        echo "$(date) $line $$: $D_NETWORK bridge network exists"
    fi
}

check_docker() {
    echo "$(date) $line $$: list of container, storage and network"
    docker ps -a
    docker system df
    docker network ls
}

if [[ $# -eq 0 ]] ; then
    echo "$(date) $line $$: No argument supplied! use '$0 $CMD_START/$CMD_STOP/$CMD_START_MON/$CMD_STOP_MON'"
else
    if [[ $# -eq 1 && $1 == $CMD_START ]] ; then
        echo "$(date) $line $$: starting all datastore services"
        check_network
        echo "$(date) $line $$: starting $D_MYSQL"
        docker run --rm --name=$D_MYSQL --network=$D_NETWORK --env "MYSQL_ROOT_PASSWORD=password" --mount type=bind,src=/Users/davidlew/Docker/mysql/etc/my.cnf,dst=/etc/my.cnf --mount type=bind,src=/Users/davidlew/Docker/mysql/data,dst=/var/lib/mysql -p 3306:3306 -d mysql/mysql-server
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_POSTGRES"
        docker run --rm --name=$D_POSTGRES --network=$D_NETWORK --env "POSTGRES_PASSWORD=password" --mount type=bind,src=/Users/davidlew/Docker/postgres/data,dst=/var/lib/postgresql/data -p 5432:5432 -d postgres
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_MONGO"
        docker run --rm --name=$D_MONGO --network=$D_NETWORK --env "MONGO_INITDB_ROOT_USERNAME=root" --env "MONGO_INITDB_ROOT_PASSWORD=password" --mount type=bind,src=/Users/davidlew/Docker/mongo/data,dst=/data/db -p 27017:27017 -d mongo
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting redis $D_REDIS"
        docker run --rm --name=$D_REDIS --network=$D_NETWORK --mount type=bind,src=/Users/davidlew/Docker/redis/data,dst=/data -p 6379:6379 -d redis
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting solr $D_SOLR"
        docker run --rm --name=$D_SOLR --network=$D_NETWORK --mount type=bind,src=/Users/davidlew/Docker/solr/data,dst=/opt/solr/server/solr --mount type=bind,src=/Users/davidlew/Docker/solr/webapp,dst=/opt/solr/server/solr-webapp -p 8983:8983 -d solr
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_STOP ]] ; then
        echo "$(date) $line $$: stopping all running services"
        docker stop $D_MYSQL $D_POSTGRES $D_MONGO $D_REDIS $D_SOLR
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_START_MON ]] ; then
        echo "$(date) $line $$: starting all monitoring services"
        check_network
        echo "$(date) $line $$: starting $D_ALERT"
        docker run --rm --name=$D_ALERT --network=$D_NETWORK --mount type=bind,src=/Users/davidlew/Docker/alertmanager/etc/alertmanager.yml,dst=/etc/alertmanager/alertmanager.yml -p 9093:9093 -d prom/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_CONTAINER"
        docker run --rm --name=$D_CONTAINER --network=$D_NETWORK --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock -p 9104:9104 -d prom/container-exporter
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_NODE"
        docker run --rm --name=$D_NODE --network=$D_NETWORK -p 9100:9100 -d prom/node-exporter
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_ADVISOR"
        docker run --rm --name=$D_ADVISOR --network=$D_NETWORK --mount type=bind,src=/,dst=/rootfs --mount type=bind,src=/var/run,dst=/var/run --mount type=bind,src=/sys,dst=/sys --mount type=bind,src=/var/lib/docker/,dst=/var/lib/docker -p 8090:8080 -d google/cadvisor
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_PROMETHEUS"
        docker run --rm --name=$D_PROMETHEUS --network=$D_NETWORK --mount type=bind,src=/Users/davidlew/Docker/prometheus/etc/prometheus.yml,dst=/etc/prometheus/prometheus.yml --mount type=bind,src=/Users/davidlew/Docker/prometheus/etc/alert_rules.yml,dst=/etc/prometheus/alert_rules.yml -p 9090:9090 -d prom/prometheus
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_GRAFANA"
        docker run --rm --name=$D_GRAFANA --network=$D_NETWORK --mount type=bind,src=/Users/davidlew/Docker/grafana/conf/grafana.ini,dst=/etc/grafana/grafana.ini --mount type=bind,src=/Users/davidlew/Docker/grafana/data,dst=/var/lib/grafana -p 3000:3000 -d grafana/grafana
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_STOP_MON ]] ; then
        echo "$(date) $line $$: stopping all monitoring services"
        docker stop $D_ALERT $D_CONTAINER $D_NODE $D_ADVISOR $D_PROMETHEUS $D_GRAFANA
        sleep $SLEEP_INT
    else
        echo "$(date) $line $$: You have gone to the wrong party! use '$0 $CMD_START/$CMD_STOP/$CMD_START_MON/$CMD_STOP_MON'"
    fi
fi
# show the docker containers and systems
check_docker
# end