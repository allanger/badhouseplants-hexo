FROM node:alpine AS build-env
COPY package.json ./
COPY package-lock.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN pwd
RUN hexo generate
RUN cp -r $PWD/public /

FROM nginx
COPY --from=build-env /public /usr/share/nginx/html