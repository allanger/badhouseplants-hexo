#FROM node AS builder
FROM node:12.22.11-buster AS builder
WORKDIR /app
COPY package.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN hexo generate --deploy
RUN cat public/index.html
CMD ["pwd"]

FROM nginx:alpine
COPY --from=builder /app/public /usr/share/nginx/html
