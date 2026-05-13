FROM nginx:1.27-alpine

RUN rm -rf /usr/share/nginx/html/*

COPY index.html manifest.json sw.js icon-192.png icon-512.png /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost/ > /dev/null || exit 1
