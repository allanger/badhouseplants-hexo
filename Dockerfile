FROM node AS build-env
COPY package.json ./
COPY package-lock.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN hexo generate
RUN ls -R
RUN pwd

FROM nginx
COPY --from=build-env /public /usr/share/nginx/html