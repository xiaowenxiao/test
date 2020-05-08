FROM nginx
COPY index.html /usr/share/nginx/html
COPY /etc/localtime /etc/localtime
