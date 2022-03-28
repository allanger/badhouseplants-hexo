FROM node AS builder
WORKDIR /app
COPY package.json ./
COPY package-lock.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN hexo generate
CMD ["pwd"]

FROM nginx
COPY --from=builder /app/public /usr/share/nginx/html
