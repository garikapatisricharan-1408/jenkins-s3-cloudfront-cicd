# Stage 1 — Build the frontend app
FROM node:18-alpine AS builder

WORKDIR /app

# Install deps first (layer caching)
COPY app/package*.json ./
RUN npm ci --prefer-offline

# Copy source and build
COPY app/ .
RUN npm run build

# Stage 2 — Lightweight Nginx to serve locally (dev/testing only)
# In prod, S3 + CloudFront handles serving
FROM nginx:alpine AS serve

COPY --from=builder /app/dist /usr/share/nginx/html

# Custom nginx config for SPA routing
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf 2>/dev/null || true

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
