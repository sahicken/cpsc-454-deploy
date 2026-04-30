# Frontend Dockerfile - Next.js app from voxguard-frontend/

FROM node:20-alpine as builder

WORKDIR /app

# Copy frontend code from voxguard-frontend submodule
COPY frontend/voxguard-frontend/package*.json ./

RUN npm ci

COPY frontend/voxguard-frontend/ .

RUN npm run build

# Runtime stage
FROM node:20-alpine

WORKDIR /app

RUN npm install -g serve

# Copy built assets
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000

# Use next start instead of serve for Next.js
CMD ["npm", "start"]
