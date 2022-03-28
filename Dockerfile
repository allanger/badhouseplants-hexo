FROM node:alpine AS build-env
WORKDIR /app
COPY package.json ./
COPY package-lock.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN pwd
RUN hexo generate
RUN cp -r /app/public /

FROM nginx:1.19.6-alpine
COPY --from=build-env /public /usr/share/nginx/html