FROM node:10-alpine
ENV URL http://9292ov.nl
ENV LOGFILEDIR /home/node/app
RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app
WORKDIR /home/node/app
COPY package*.json ./
USER node
RUN npm install
COPY --chown=node:node . .
CMD [ "npm","start" ]
