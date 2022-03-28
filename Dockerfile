FROM node:alpine AS build-env
COPY package.json ./
COPY package-lock.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN pwd
CMD ["hexo", "generate"]

FROM nginx
COPY --from=build-env /public /usr/share/nginx/html