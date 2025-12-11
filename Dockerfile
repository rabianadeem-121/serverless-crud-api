FROM node:18

WORKDIR /app

# Install SSH client & netcat
RUN apt-get update && \
    apt-get install -y openssh-client netcat && \
    rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000
CMD ["npm", "start"]
