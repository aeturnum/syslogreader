# Syslogreader

This is a simple syslog forwarder that will stream the logs for the configured programs to a web browser. 

It uses `plug` and `cowboy` and is very bare bones. It was useful for informal development as well as a fun little experiment to write.

A "demo" can be seen [here](https://admin.drex.space/) - enjoy the overly verbose logs of [doctor spins](https://github.com/aeturnum/spins_halp_line)!

## Installation

Clone this repo, set the service you want to monitor in `config.exs` and `mix run --no-halt`. The server runs on port `4000`. 

Here is the nginx config I'm using to serve this:

```
upstream admin {
  server localhost:4000; # elixir log formatter
}

# redirect all http requests to https
# and also listen on IPv6 addresses
server {
    if ($host = admin.drex.space) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


  listen 80;
  listen [::]:80;
  server_name admin.drex.space www.admin.drex.space;

  return 301 https://$server_name$request_uri;


}

# the main server directive for ssl connections
# where we also use http2 (see asset delivery)
server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name admin.drex.space admin.www.drex.space;

  # paths to certificate and key provided by Let's Encrypt

  # SSL settings that currently offer good results in the SSL check
  # and have a reasonable backwards-compatibility, taken from
  # - https://cipherli.st/
  # - https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
  ssl_ecdh_curve secp384r1;
  ssl_session_cache shared:SSL:10m;
  ssl_session_tickets off;
  ssl_stapling on;
  ssl_stapling_verify on;
  #ssl_dhparam /etc/ssl/certs/dhparam.pem;

  # security enhancements
  add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;

  # Let's Encrypt keeps its files here
  location ~ /.well-known {
    root /var/www/html;
    allow all;
  }


  # besides referencing the extracted upstream this stays the same
  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_pass http://admin;
    proxy_http_version 1.1;
    proxy_ssl_certificate /etc/letsencrypt/live/admin.drex.space/fullchain.pem; # managed by Certbot
    proxy_ssl_certificate_key /etc/letsencrypt/live/admin.drex.space/privkey.pem; # managed by Certbot
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
  }

    ssl_certificate /etc/letsencrypt/live/admin.drex.space/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/admin.drex.space/privkey.pem; # managed by Certbot
}

```
