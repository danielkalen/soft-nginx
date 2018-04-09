FROM nginx:1.13
RUN rm /var/log/nginx/access.log /var/log/nginx/error.log
RUN apt-get update &&\
	apt-get install -y apt-transport-https lsb-release build-essential curl

RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - &&\
	apt-get install -y nodejs

WORKDIR /app/
ENV NPM_CONFIG_LOGLEVEL warn
ENV SOURCE_MAPS 1

COPY package.json package.json
RUN npm install

COPY index.js index.js
COPY config config
COPY entrypoint entrypoint
COPY error-pages error-pages

CMD ["node", "index.js"]