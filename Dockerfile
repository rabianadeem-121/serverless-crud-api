FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy app code
COPY . .

# Expose port (optional, Lambda doesn't need it but for local testing)
EXPOSE 3000

# Start the app
CMD ["node", "index.js"]
