# Use official Node.js image
FROM node:18

# Install SSH client & netcat
RUN apt-get update && \
    apt-get install -y openssh-client netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the code
COPY . .

# Default command (run tests or app)
CMD ["npm", "test"]
