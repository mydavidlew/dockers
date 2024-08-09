docker run -it --rm --name=neo4j --network=appnet --user="$(id -u):$(id -g)" -e NEO4J_AUTH=none -v $PWD/data:/data -p 7474:7474 -p 7687:7687 neo4j:latest


#docker run -it --rm \
#    --publish=7474:7474 --publish=7687:7687 \
#    --volume=$HOME/neo4j/data:/data \
#    neo4j:latest

#docker run -it --rm \
#  --publish=7474:7474 --publish=7687:7687 \
#  --user="$(id -u):$(id -g)" \
#  -e NEO4J_AUTH=none \
#  --env NEO4J_PLUGINS='["graph-data-science"]' \
#  neo4j:latest
