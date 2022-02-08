# AWS Lambda API - DynamoDB - S3 - React


This is a simple project that creates a newsletter subscription application using AWS Lambda functions.

The frontend should be hosted in a CDN, in this case I'm using S3 Static website hosting.

The Lambda is made of javascript and will persist the data in a DynamoDB

- "apiLambda" Folder : Contains the lambda function
- "subscriber" Folder : Contains the simple React application
- "terraform" Folder : Contains a terraform script that will take care of Infrastructure provision in the AWS Cloud.

---
## Requirements

- Terraform
- NodeJS 
- AWS CLI
- AWS Credentials

---
## Installation

- Inside "Terraform" folder
- RUN
```bash
terraform init
terraform plan
terraform apply
```
- Get the API Gateway URL from terraform output
- Inside the "subscriber" folder, change the `ENDPOINT_URL` inside `src/App.tsx` to the API Gateway URL
- RUN
```bash
npm run build
```
- Upload the `dist/` folder content to the created S3 Bucket
- You can get the public URL inside the S3 Bucket properties tab
- Have fun ❤️

If you want to change the lambda code, you should replace the `apiLambda.zip` inside "terraform" folder.