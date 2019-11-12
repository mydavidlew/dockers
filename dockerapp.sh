[Docker-A]
#!/bin/bash
SLEEP_INT=1
CMD_START=start; CMD_STOP=stop
CMD_START_MON=start-monitor; CMD_STOP_MON=stop-monitor
D_NETWORK=appnet
D_MYSQL=mysql1; D_POSTGRES=postgres1; D_MONGO=mongo1; D_REDIS=redis1; D_SOLR=solr1
D_ALERT=alertmanager1; D_CONTAINER=container-exporter1; D_NODE=node-exporter1; D_ADVISOR=cadvisor1; D_PROMETHEUS=prometheus1; D_GRAFANA=grafana1

C_DOCKER="docker run --rm -d"
C_MOUNT="--mount type=bind"
L_PATH="/opt/docker"

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
        $C_DOCKER --name=$D_MYSQL --network=$D_NETWORK --env "MYSQL_ROOT_PASSWORD=password" $C_MOUNT,src=$L_PATH"/mysql/etc/my.cnf",dst=/etc/my.cnf $C_MOUNT,src=$L_
PATH"/mysql/data",dst=/var/lib/mysql -p 3306:3306 mysql/mysql-server
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_POSTGRES"
        $C_DOCKER --name=$D_POSTGRES --network=$D_NETWORK --env "POSTGRES_PASSWORD=password" $C_MOUNT,src=$L_PATH"/postgres/data",dst=/var/lib/postgresql/data -p 54
32:5432 postgres
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_MONGO"
        $C_DOCKER --name=$D_MONGO --network=$D_NETWORK --env "MONGO_INITDB_ROOT_USERNAME=root" --env "MONGO_INITDB_ROOT_PASSWORD=password" $C_MOUNT,src=$L_PATH"/mon
go/data",dst=/data/db -p 27017:27017 mongo
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting redis $D_REDIS"
        $C_DOCKER --name=$D_REDIS --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/redis/data",dst=/data -p 6379:6379 redis
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting solr $D_SOLR"
        $C_DOCKER --name=$D_SOLR --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/solr/data",dst=/opt/solr/server/solr $C_MOUNT,src=$L_PATH"/solr/webapp",dst=/opt/solr/se
rver/solr-webapp -p 8983:8983 solr
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_STOP ]] ; then
        echo "$(date) $line $$: stopping all running services"
        docker stop $D_MYSQL $D_POSTGRES $D_MONGO $D_REDIS $D_SOLR
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_START_MON ]] ; then
        echo "$(date) $line $$: starting all monitoring services"
        check_network
        echo "$(date) $line $$: starting $D_CONTAINER"
        $C_DOCKER --name=$D_CONTAINER --network=$D_NETWORK $C_MOUNT,src=/var/run/docker.sock,dst=/var/run/docker.sock -p 9104:9104 prom/container-exporter
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_NODE"
        $C_DOCKER --name=$D_NODE --network=$D_NETWORK -p 9100:9100 prom/node-exporter
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_ADVISOR"
        $C_DOCKER --name=$D_ADVISOR --network=$D_NETWORK $C_MOUNT,src=/,dst=/rootfs $C_MOUNT,src=/var/run,dst=/var/run $C_MOUNT,src=/sys,dst=/sys $C_MOUNT,src=/var/
lib/docker/,dst=/var/lib/docker -p 9109:8080 google/cadvisor
        sleep $SLEEP_INT
#        echo "$(date) $line $$: starting $D_ALERT"
#        $C_DOCKER --name=$D_ALERT --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/alertmanager/etc/alertmanager.yml",dst=/etc/alertmanager/alertmanager.yml -p 9093:9093
 prom/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
#        sleep $SLEEP_INT
#        echo "$(date) $line $$: starting $D_PROMETHEUS"
#        $C_DOCKER --name=$D_PROMETHEUS --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/prometheus/etc/prometheus.yml",dst=/etc/prometheus/prometheus.yml $C_MOUNT,src=$L
_PATH"/prometheus/etc/alert_rules.yml",dst=/etc/prometheus/alert_rules.yml -p 9090:9090 prom/prometheus
#        sleep $SLEEP_INT
#        echo "$(date) $line $$: starting $D_GRAFANA"
#        $C_DOCKER --name=$D_GRAFANA --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/grafana/conf/grafana.ini",dst=/etc/grafana/grafana.ini $C_MOUNT,src=$L_PATH"/grafana
/data",dst=/var/lib/grafana -p 3000:3000 grafana/grafana
#        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_STOP_MON ]] ; then
        echo "$(date) $line $$: stopping all monitoring services"
        docker stop $D_CONTAINER $D_NODE $D_ADVISOR
#        docker stop $D_ALERT $D_CONTAINER $D_NODE $D_ADVISOR $D_PROMETHEUS $D_GRAFANA
        sleep $SLEEP_INT
    else
        echo "$(date) $line $$: You have gone to the wrong party! use '$0 $CMD_START/$CMD_STOP/$CMD_START_MON/$CMD_STOP_MON'"
    fi
fi
# show the docker containers and systems
check_docker
# end



[Docker-B]
#!/bin/bash
SLEEP_INT=1
CMD_START=start; CMD_STOP=stop
CMD_START_MON=start-monitor; CMD_STOP_MON=stop-monitor
D_NETWORK=appnet
D_MYSQL=mysql1; D_POSTGRES=postgres1; D_MONGO=mongo1; D_REDIS=redis1; D_SOLR=solr1
D_ALERT=alertmanager1; D_CONTAINER=container-exporter1; D_NODE=node-exporter1; D_ADVISOR=cadvisor1; D_PROMETHEUS=prometheus1; D_GRAFANA=grafana1

C_DOCKER="docker run --rm -d"
C_MOUNT="--mount type=bind"
L_PATH="/Users/davidlew/Docker"

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
        $C_DOCKER --name=$D_MYSQL --network=$D_NETWORK --env "MYSQL_ROOT_PASSWORD=password" $C_MOUNT,src=$L_PATH"/mysql/etc/my.cnf",dst=/etc/my.cnf $C_MOUNT,src=$L_PATH"/mysql/data",dst=/var/lib/mysql -p 3306:3306 mysql/mysql-server
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_POSTGRES"
        $C_DOCKER --name=$D_POSTGRES --network=$D_NETWORK --env "POSTGRES_PASSWORD=password" $C_MOUNT,src=$L_PATH"/postgres/data",dst=/var/lib/postgresql/data -p 5432:5432 postgres
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_MONGO"
        $C_DOCKER --name=$D_MONGO --network=$D_NETWORK --env "MONGO_INITDB_ROOT_USERNAME=root" --env "MONGO_INITDB_ROOT_PASSWORD=password" $C_MOUNT,src=$L_PATH"/mongo/data",dst=/data/db -p 27017:27017 mongo
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting redis $D_REDIS"
        $C_DOCKER --name=$D_REDIS --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/redis/data",dst=/data -p 6379:6379 redis
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting solr $D_SOLR"
        $C_DOCKER --name=$D_SOLR --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/solr/data",dst=/opt/solr/server/solr $C_MOUNT,src=$L_PATH"/solr/webapp",dst=/opt/solr/server/solr-webapp -p 8983:8983 solr
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_STOP ]] ; then
        echo "$(date) $line $$: stopping all running services"
        docker stop $D_MYSQL $D_POSTGRES $D_MONGO $D_REDIS $D_SOLR
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_START_MON ]] ; then
        echo "$(date) $line $$: starting all monitoring services"
        check_network
        echo "$(date) $line $$: starting $D_ALERT"
        $C_DOCKER --name=$D_ALERT --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/alertmanager/etc/alertmanager.yml",dst=/etc/alertmanager/alertmanager.yml -p 9093:9093 prom/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_CONTAINER"
        $C_DOCKER --name=$D_CONTAINER --network=$D_NETWORK $C_MOUNT,src=/var/run/docker.sock,dst=/var/run/docker.sock -p 9104:9104 prom/container-exporter
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_NODE"
        $C_DOCKER --name=$D_NODE --network=$D_NETWORK -p 9100:9100 prom/node-exporter
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_ADVISOR"
        $C_DOCKER --name=$D_ADVISOR --network=$D_NETWORK $C_MOUNT,src=/,dst=/rootfs $C_MOUNT,src=/var/run,dst=/var/run $C_MOUNT,src=/sys,dst=/sys $C_MOUNT,src=/var/lib/docker/,dst=/var/lib/docker -p 8090:8080 google/cadvisor
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_PROMETHEUS"
        $C_DOCKER --name=$D_PROMETHEUS --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/prometheus/etc/prometheus.yml",dst=/etc/prometheus/prometheus.yml $C_MOUNT,src=$L_PATH"/prometheus/etc/alert_rules.yml",dst=/etc/prometheus/alert_rules.yml -p 9090:9090 prom/prometheus
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_GRAFANA"
        $C_DOCKER --name=$D_GRAFANA --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/grafana/conf/grafana.ini",dst=/etc/grafana/grafana.ini $C_MOUNT,src=$L_PATH"/grafana/data",dst=/var/lib/grafana -p 3000:3000 grafana/grafana
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



[Docker-C]
#!/bin/bash
SLEEP_INT=1
CMD_START=startd; CMD_STOP=stopd
CMD_START_MON=start; CMD_STOP_MON=stop
D_NETWORK=appnet
D_ES1=elasticsearch; D_KI1=kibana; D_LS1=logstash
D_CON1=elastic1; D_CON2=kibana1; D_CON3=logstash1; D_CON4=filebeat1; D_CON5=none1; D_CON6=none1

C_DOCKER="docker run --rm -d"
C_MOUNT="--mount type=bind"
L_PATH="/opt/docker"

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
        echo "$(date) $line $$: starting $D_CON6"
        $C_DOCKER --name=$D_CON6 --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/null",dst=/null -p 0000:0000 null
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_STOP ]] ; then
        echo "$(date) $line $$: stopping all running services"
        docker stop $D_CON6
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_START_MON ]] ; then
        echo "$(date) $line $$: starting all monitoring services"
        check_network
        echo "$(date) $line $$: starting $D_CON1"
        $C_DOCKER --name=$D_CON1 --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/elasticsearch/conf",dst=/usr/share/elasticsearch/config $C_MOUNT,src=$L_PATH"/elasticse
arch/data",dst=/usr/share/elasticsearch/data --env "discovery.type=single-node" --env "cluster.name=elastic-cluster" -p 9200:9200 -p 9300:9300 docker.elastic.co/el
asticsearch/elasticsearch:7.2.0
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_CON2"
        $C_DOCKER --name=$D_CON2 --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/kibana/conf",dst=/usr/share/kibana/config --link $D_CON1:$D_ES1 -p 5601:5601 docker.ela
stic.co/kibana/kibana:7.2.0
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_CON3"
        $C_DOCKER --name=$D_CON3 --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/logstash/conf",dst=/usr/share/logstash/config $C_MOUNT,src=$L_PATH"/logstash/pipeline",
dst=/usr/share/logstash/pipeline --link $D_CON1:$D_ES1 -p 5044:5044 docker.elastic.co/logstash/logstash:7.2.0
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_CON4"
        $C_DOCKER --name=$D_CON4 --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/filebeat/conf/filebeat.yml",dst=/usr/share/filebeat/filebeat.yml $C_MOUNT,src=$L_PATH"/
filebeat/vmlog",dst=/usr/share/filebeat/logs --link $D_CON1:$D_ES1 --link $D_CON2:$D_KI1 --link $D_CON3:$D_LS1 docker.elastic.co/beats/filebeat:7.2.0
        sleep $SLEEP_INT
        echo "$(date) $line $$: starting $D_CON5"
        $C_DOCKER --name=$D_CON5 --network=$D_NETWORK $C_MOUNT,src=$L_PATH"/null",dst=/null -p 0000:0000 null
        sleep $SLEEP_INT
    elif [[ $# -eq 1 && $1 == $CMD_STOP_MON ]] ; then
        echo "$(date) $line $$: stopping all monitoring services"
        docker stop $D_CON1 $D_CON2 $D_CON3 $D_CON4 $D_CON5
        sleep $SLEEP_INT
    else
        echo "$(date) $line $$: You have gone to the wrong party! use '$0 $CMD_START/$CMD_STOP/$CMD_START_MON/$CMD_STOP_MON'"
    fi
fi
# show the docker containers and systems
check_docker
# end
