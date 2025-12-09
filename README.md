
# Serverless CRUD REST API with AWS Lambda and RDS (PostgreSQL)
## Project Overview
This project implements a **serverless CRUD (Create, Read, Update, Delete) REST API** using **Node.js**, **AWS Lambda**, **Amazon API Gateway**, and **Amazon RDS PostgreSQL**.
The API allows users to perform CRUD operations on a `users` table in PostgreSQL. All requests are routed through **API Gateway** to a **single AWS Lambda function**, which interacts with the RDS database inside a **VPC** for secure access. CloudWatch logs monitor Lambda executions.
---
**Flow:**
1. Client (Postman / Browser / App) sends HTTP request. 
2. API Gateway receives the request and triggers Lambda. 
3. Lambda executes CRUD logic and connects to PostgreSQL (inside VPC). 
4. Database returns the result to Lambda. 
5. Lambda sends response back to API Gateway. 
6. API Gateway returns JSON response to the client.
---
## Features
- Create User → Insert new record into the database 
- Read All Users → Fetch all users 
- Read User by ID → Fetch a single user by ID 
- Update User → Modify existing user 
- Delete User → Remove a user by ID 
---
## Technology Stack
- Node.js (JavaScript) 
- AWS Lambda (single file for all CRUD operations) 
- Amazon RDS PostgreSQL 
- API Gateway (REST API, Regional, TLS 1.3) 
- AWS VPC and Security Groups 
- AWS CloudWatch Logs 
---
## API Endpoints
| Method | Endpoint        | Description          |
|--------|----------------|--------------------|
| POST   | `/users`       | Create a new user   |
| GET    | `/users`       | Get all users       |
| GET    | `/users/{id}`  | Get a user by ID    |
| PUT    | `/users/{id}`  | Update a user by ID |
| DELETE | `/users/{id}`  | Delete a user by ID |
---
## Environment Variables
The Lambda function requires the following environment variables:
| Variable    | Description           |
|------------|-----------------------|
| DB_HOST    | RDS endpoint (hostname)|
| DB_USER    | Database username      |
| DB_PASSWORD| Database password      |
| DB_NAME    | Database name          |
> **Security Tip:** Never hardcode credentials in your code. Use environment variables or AWS Secrets Manager.
---
## Database Table
SQL to create the `users` table:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL
);
```
## Setup Instructions

### **1. AWS Infrastructure**

1. **Create a VPC** with private subnets for Lambda and RDS.  
2. **Create Security Groups:**  
   - **RDS-SG:** Allow inbound PostgreSQL (**port 5432**) from **Lambda-SG**.  
   - **Lambda-SG:** Allow outbound traffic to RDS.  
3. **Launch Amazon RDS PostgreSQL** in private subnets.  
4. **Enable CloudWatch Logging** for Lambda.

### **2. Deploy Lambda Function**

1. **Upload `index.js`** (single file with all CRUD logic) to Lambda.  
2. Add **environment variables**: `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`.  
3. Attach Lambda to the **VPC** and select the correct subnets and security group.  
4. Assign **IAM role** with Lambda execution permissions.  

> **Note:** The Lambda file contains all CRUD logic. The handler routes requests based on HTTP method and path.

### **3. Configure API Gateway**

1. Create a **REST API** (Regional, TLS 1.3).  
2. Add **resources and methods:**  
   - `/users` → `GET`, `POST`  
   - `/users/{id}` → `GET`, `PUT`, `DELETE`  
3. Enable **Lambda Proxy Integration** for all methods.  
4. Deploy API to a stage (e.g., `dev`) to generate the **Invoke URL**.

### **4. Test API Endpoints**

Use **Postman** or **curl** for testing:

**Create User (POST /users)**

```http
POST https://<invoke-url>/users
Content-Type: application/json

{
  "name": "Rabia",
  "email": "rabia@example.com"
}
```
**Create User (POST /users)**
```http
POST https://<invoke-url>/users
Body:
{
  "name": "Rabia",
  "email": "rabia@example.com"
}
```
**Get All Users (GET /users)**
```http
GET https://<invoke-url>/users
```
**Get User by ID (GET /users/1)**
```http
GET https://<invoke-url>/users/1
```
**Update User (PUT /users/1)**
```http
PUT https://<invoke-url>/users/1
Body:
{
  "name": "Rabia Updated",
  "email": "rabia.new@example.com"
}
```
**Delete User (DELETE /users/1)**
```http
DELETE https://<invoke-url>/users/1
```
---
### Testing & Logging
Use Postman or curl to test each endpoint.
All Lambda executions are logged in CloudWatch, including request method, body, SQL queries, and errors.


