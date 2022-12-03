# Here we define a cluster of hunchentoot servers
# this can later be extend for load-balancing
# if we had more instances of hunchentoot. In this
# case i only have one instance running.
upstream hunchentoot {
    server 127.0.0.1:4244;
	      }

	      upstream webpushserver {
	      server 127.0.0.1:4345;
	      }

server {
    listen 443 ssl;
    server_name highrisehub.com www.highrisehub.com;
    root /data/www/highrisehub.com/public;

    ssl_certificate /etc/letsencrypt/live/highrisehub.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/highrisehub.com/privkey.pem; # managed by Certbot
   
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

	      index index.html;
	      rewrite ^(.*)/$ $1/index.html;


	      # Expire rules for static content

	    
	      # Media: images, icons, video, audio, HTC
	      location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
	      expires 1M;
	      access_log off;
	      add_header Cache-Control "public";
	      }

	      # CSS and Javascript
	      location ~* \.(?:css|js)$ {
	      expires 1y;
	      access_log off;
	      add_header Cache-Control "public";
	      }

	      
	      
    # General request handling this will match all locations
    location / {
	      
	  

        # Define custom HTTP Headers to be used when proxying
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;


        # if the requested file does not exist then
        # rewrite to the correct hunchentoot path
        # so that the proxy_pass can catch and pass on
        # to hunchentoot correctly - proxy_pass
        # cannot have anything but the servername/ip in it
        # else nginx complains so we have to rewrite and then
        # catch in another location later

     if (!-f $request_filename) {
                rewrite ^/(.*)$ /hhub/$1 last;
                break;
        }

    }

    location /hhub/ {
        # proxy to the hunchentoot server cluster
         proxy_pass http://hunchentoot;
    }

	      location /push/ {
	      # proxy to webpush node server
	      proxy_pass http://webpushserver;
	      }
	      
 
}

server { 

	      listen 80; 
	      server_name highrisehub.com www.highrisehub.com;
	      listen [::]:80 default_server ipv6only=on;

    if ($host = www.highrisehub.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    if ($host = highrisehub.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    return 404; # managed by Certbot


}
