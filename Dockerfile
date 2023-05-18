FROM node:7
ADD app.js /app.js
ENTRYPOINT ["bash","-c","node app.js"]
