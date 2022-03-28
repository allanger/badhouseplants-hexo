FROM node:alpine AS build-env
WORKDIR /app
COPY package.json ./
COPY package-lock.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN pwd
CMD ["hexo", "generate"]

FROM nginx:1.19.6-alpine
COPY --from=build-env /app/public //usr/share/nginx/html
# COPY configs/ng`inx/nginx.conf /etc/nginx/conf.d/default.conf