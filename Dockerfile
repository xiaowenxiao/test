FROM nginx
WORKDIR /usr/share/
COPY index.html /usr/share/nginx/html
COPY localtime /etc/localtime
COPY README.md .