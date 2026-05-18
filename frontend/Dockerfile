# ============================================================
# Task 4a: Frontend — Nginx serving a static HTML/JS app
# ============================================================
FROM nginx:alpine

LABEL description="Lab2 Frontend - Static site served by Nginx"

# Install OpenSSL so we can generate a local self-signed certificate.
RUN apk add --no-cache openssl \
	&& mkdir -p /etc/nginx/certs \
	&& openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
	   -subj "/CN=notes.localhost" \
	   -addext "subjectAltName=DNS:notes.localhost,DNS:localhost,IP:127.0.0.1" \
	   -keyout /etc/nginx/certs/notes.localhost.key \
	   -out /etc/nginx/certs/notes.localhost.crt

# Remove default page
RUN rm -rf /usr/share/nginx/html/*

# Copy static assets
COPY index.html /usr/share/nginx/html/index.html

# Copy custom nginx config (proxy /api requests to backend)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
