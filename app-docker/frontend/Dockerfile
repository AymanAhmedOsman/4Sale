# Non-root nginx that listens on 8080 by default
#FROM nginxinc/nginx-unprivileged:1.27-alpine
FROM nginx:1.27-alpine

# Copy configuration and static content
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html  /usr/share/nginx/html/index.html

EXPOSE 8080
