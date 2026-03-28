# Build estático (Vite). VITE_API_BASE_URL en tiempo de build.
# Workaround para bug de npm con rollup optional dependencies (github.com/npm/cli/issues/4828)

FROM node:20-slim AS build
WORKDIR /app

COPY package*.json ./

# Eliminar package-lock.json y usar npm install para evitar bug de rollup
RUN rm -f package-lock.json && npm install

COPY . .

ARG VITE_API_BASE_URL=http://localhost:3000
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

RUN npm run build

FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="transport-frontend"
LABEL org.opencontainers.image.description="Vue SPA (Transportes)"

RUN apk add --no-cache wget

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1

EXPOSE 80
