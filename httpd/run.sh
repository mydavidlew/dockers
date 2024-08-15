docker run -it --rm --name=apache --network=appnet -v $PWD/conf/httpd.conf:/usr/local/apache2/conf/httpd.conf -v $PWD/data:/usr/local/apache2/htdocs -p 80:80 -p 443:443 httpd:latest

# To customize the configuration of the httpd server, first obtain the upstream default configuration from the container
#docker run -it --rm --name=apache --network=appnet -p 80:80 -p 443:443 httpd:latest
#docker run --rm httpd:latest cat /usr/local/apache2/conf/httpd.conf > conf/httpd.conf
#docker run --rm httpd:latest cat /usr/local/apache2/htdocs/index.html > data/index.html
#docker exec -it apache bash