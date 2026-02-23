# ==========================================
# BaristaBot Pro - Production Dockerfile
# Multi-stage build for optimization
# ==========================================

# Stage 1: Dependencies
FROM node:18-alpine AS dependencies

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Stage 2: Production
FROM node:18-alpine AS production

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

WORKDIR /app

# Copy dependencies from stage 1
COPY --from=dependencies /app/node_modules ./node_modules

# Copy app source
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start server
CMD ["node", "server.js"]
