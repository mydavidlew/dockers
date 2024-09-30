docker run -it --rm --name=neo4j --network=appnet --user="$(id -u):$(id -g)" -e NEO4J_AUTH=none \
  -v $PWD/data:/data -v $PWD/conf:/var/lib/neo4j/conf \
  --publish=7474:7474 --publish=7687:7687 \
  --env NEO4J_PLUGINS='["graph-data-science"]' \
  --env NEO4J_apoc_export_file_enabled=true \
  --env NEO4J_apoc_import_file_enabled=true \
  --env NEO4J_apoc_import_file_use__neo4j__config=true \
  --env NEO4J_PLUGINS='["apoc"]' \
  neo4j:latest

# GDS Plugins
#docker run -it --rm --name=neo4j --network=appnet --user="$(id -u):$(id -g)" -e NEO4J_AUTH=none \
#  -v $PWD/data:/data -v $PWD/conf:/var/lib/neo4j/conf \
#  --publish=7474:7474 --publish=7687:7687 \
#  --env NEO4J_PLUGINS='["graph-data-science"]' \
#  neo4j:latest

# APOC Plugins
#docker run \
#    -p 7474:7474 -p 7687:7687 \
#    --name neo4j-apoc \
#    -e NEO4J_apoc_export_file_enabled=true \
#    -e NEO4J_apoc_import_file_enabled=true \
#    -e NEO4J_apoc_import_file_use__neo4j__config=true \
#    -e NEO4J_PLUGINS=\[\"apoc\"\] \
#    neo4j:5.24.0