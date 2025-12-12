# Use AWS Lambda Node.js 18 runtime base image
FROM public.ecr.aws/lambda/nodejs:18

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy app code
COPY . .

# Set the CMD to your Lambda handler
CMD ["index.handler"]
