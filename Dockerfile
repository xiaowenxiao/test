FROM nginx
COPY index.html /usr/share/nginx/html
COPY localtime /etc/localtime