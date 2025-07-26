FROM node:22.17.1-bullseye
COPY . .
RUN npm install
RUN npm run build
ENTRYPOINT ["npm","start"]