FROM node:alpine

WORKDIR /app

# On copie d'abord uniquement le package.json pour profiter du cache Docker
# (si le code change mais pas les dependances, npm install n'est pas rejoue)
COPY package.json ./
RUN npm install

# On copie ensuite le reste du code du service
COPY ./ ./

CMD ["npm", "start"]
