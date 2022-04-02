FROM node AS builder
WORKDIR /app
COPY package.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN hexo generate --deploy

FROM nginx:alpine
COPY --from=builder /app/public /usr/share/nginx/html
