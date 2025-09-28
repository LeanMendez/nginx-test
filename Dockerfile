# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm ci --only=production --silent

# Copy source and build
COPY . .
RUN npm run build

# Production stage - use alpine for smaller size
FROM nginx:alpine

# Copy optimized nginx config
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Create nginx cache directories with proper permissions
RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
             /tmp

# Set proper permissions for nginx user
RUN chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown nginx:nginx /tmp && \
    chmod -R 755 /usr/share/nginx/html

EXPOSE 80

# Use nginx user for security
USER nginx

CMD ["nginx", "-g", "daemon off;"]