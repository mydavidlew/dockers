docker run -it --rm --name=neo4j --network=appnet --user="$(id -u):$(id -g)" -e NEO4J_AUTH=none \
  -v $PWD/data:/data -v $PWD/conf:/var/lib/neo4j/conf \
  --publish=7474:7474 --publish=7687:7687 \
  --env NEO4J_PLUGINS='["graph-data-science"]' \
  neo4j:latest

#docker run -it --rm --name=neo4j --network=appnet --user="$(id -u):$(id -g)" -e NEO4J_AUTH=none \
#  --publish=7474:7474 --publish=7687:7687 \
#  --env NEO4J_PLUGINS='["graph-data-science"]' \
#  neo4j:latest
