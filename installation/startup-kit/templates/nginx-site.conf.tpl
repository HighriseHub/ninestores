# nginx vhost for @DOMAIN@ — rendered by installation/startup-kit/06-install-nginx.sh
#
# Two ideas carry this whole file:
#
#  1. ONE Hunchentoot instance serves EVERY domain, because Hunchentoot has no
#     virtual-host support and define-easy-handler uses a single global dispatch
#     table. The workaround is a URL prefix inside Lisp (@URL_PREFIX@) that nginx
#     rewrites into. Adding a second domain = copy this file, change
#     server_name; the Lisp side needs no knowledge of it.
#
#  2. Static files are served by nginx and never reach the image; only what is
#     NOT a file on disk is rewritten into the proxy.

upstream hunchentoot {
    server 127.0.0.1:@HTTP_PORT@;
    # more instances here if this ever needs load balancing
}

# the three node servers (pm2). Each is a separate process with its own port;
# nginx is the only thing that exposes them.
upstream webpushserver  { server 127.0.0.1:@WEBPUSH_PORT@; }
upstream awssnssmsserver { server 127.0.0.1:@SMS_PORT@; }
upstream awss3bucket    { server 127.0.0.1:@S3_PORT@; }

server {
    listen 80;
    listen [::]:80;
    server_name @DOMAIN@ @ALIASES@;

    root @WWW_ROOT@;
    index index.html;
    rewrite ^(.*)/$ $1/index.html;

    # ── static: long-lived, logged off ──────────────────────────────────────
    location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc)$ {
        expires 1M;
        access_log off;
        add_header Cache-Control "public";
    }

    location ~* \.(?:css|js)$ {
        expires 1y;
        access_log off;
        add_header Cache-Control "public";
    }

    # ── everything else ─────────────────────────────────────────────────────
    location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # not a real file on disk? hand it to the Lisp under the prefix.
        # the rewrite is needed because proxy_pass may not carry a path of its
        # own here — so rewrite first, then catch it in the location below.
        if (!-f $request_filename) {
            rewrite ^/(.*)$ @URL_PREFIX@$1 last;
            break;
        }
    }

    location @URL_PREFIX@ {
        proxy_pass http://hunchentoot;
    }

    location /push/ {
        proxy_pass http://webpushserver;
    }

    location /sms/ {
        proxy_pass http://awssnssmsserver;
    }

    location /file/ {
        proxy_pass http://awss3bucket;
    }
}
