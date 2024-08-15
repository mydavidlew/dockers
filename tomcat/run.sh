docker run -it --rm --name=tomcat --network=appnet -v $PWD/conf/server.xml:/usr/local/tomcat/conf/server.xml -v $PWD/data:/usr/local/tomcat/webapps -p 8080:8080 -p 8443:8443 tomcat:latest

# To customize the configuration of the tomcat server, first obtain the upstream default configuration from the container
#docker run -it --rm --name=tomcat --network=appnet -p 8080:8080 -p 8443:8443 tomcat:latest
#docker run --rm tomcat:latest cat /usr/local/tomcat/conf/server.xml > conf/server.xml
#docker run --rm tomcat:latest cat /usr/local/tomcat/webapps/index.html > data/index.html
#docker exec -it tomcat bash