FROM node:alpine AS img_base
WORKDIR /app/front
COPY front/package*.json /app/front
RUN npm install
COPY front/ .
RUN npm run build

FROM node:alpine
WORKDIR /app/back
COPY back/package*.json .
COPY --from=img_base app/front/dist public

RUN npm install

COPY back/index.js /app/back

RUN mkdir /app/node && adduser -D nodeapp && chown -R nodeapp:nodeapp /app/node

USER nodeapp

EXPOSE 1111

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "executable" ]

CMD [ "npm", "start" ]
