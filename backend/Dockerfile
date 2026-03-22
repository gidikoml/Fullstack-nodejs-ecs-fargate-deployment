FROM node:20-slim

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm config set registry https://registry.npmjs.org/ \
    && npm config set fetch-retries 5 \
    && npm config set fetch-retry-mintimeout 10000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm cache clean --force \
    && npm install --omit=dev --package-lock=false --no-audit --no-fund

COPY . .

EXPOSE 80

CMD ["node", "index.js"]
