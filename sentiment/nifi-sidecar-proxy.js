const https = require('https');
const http = require('http');
const fs = require('fs');

process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = 0;
const allowedHosts = [];

function onHTTPRequest(req, res) {
    const { headers, url } = req;
    const { host } = headers;
    let isAllowedHost = false;
    if (allowedHosts && allowedHosts.length && allowedHosts.length > 0) {
        isAllowedHost = allowedHosts.findIndex(allowedHost => allowedHost === host) > -1;
    }

    if (!isAllowedHost) {
        res.end();
        console.warn(`Blocked an incoming HTTP request from ${host} for url: ${url}`);
        return;
    }

    res.redirect(`https://${req.headers.host}${req.url}`);
}

function onHTTPSRequest(client_req, client_res) {
    console.log('serve: ' + client_req.url);
    const nifi_host = process.env.NIFI_HOST;
    console.log(nifi_host);
    try {
        var options = {
            hostname: nifi_host,
            port: 8443,
            path: client_req.url,
            method: client_req.method,
            headers: {
                ...client_req.headers,
                "X-ProxyScheme": "https",
                "X-ProxyHost": `${process.env.ALLOWED_HOSTS}`,
                "X-ProxyPort": "443",
                "X-ProxyContextPath": "/"
            }
        };

        var proxy = https.request(options, function(res) {
            try {
                client_res.writeHead(res.statusCode, res.headers)
                res.pipe(client_res, {
                    end: true
                });
            } catch (err) {
                console.error(err);
            }
        });

        client_req.pipe(proxy, {
            end: true
        });
    } catch (err) {
        console.err(err);
    }
}

(function() {
    console.info(`Starting sidecar with env vars - 
        - ALLOWED_HOSTS: ${process.env.ALLOWED_HOSTS}
        - NIFI_HOST: ${process.env.NIFI_HOST}`);

    if (process.env.ALLOWED_HOSTS) {
        process.env.ALLOWED_HOSTS.split(",").forEach(host => allowedHosts.push(host));
    }

    http.createServer({}, onHTTPSRequest).listen(9443, "0.0.0.0", function() {
        console.info("The sidecar proxy is listening for HTTPS requests on port 9443.");
    });

    http.createServer({}, onHTTPRequest).listen(9080, "0.0.0.0", function() {
        console.info("The sidecar proxy is listening for HTTP requests on port 9080");
    });
}());