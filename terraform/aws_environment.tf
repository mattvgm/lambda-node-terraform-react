
##### BLOCO VARIAVEIS
variable "awsvars" {
    type = map(string)
    default = {
    region = "us-east-1"
    s3_bucket_name = "newslambda-b"
    dynamo_db_name = "newsletter"
    lambda_name = "lambdynamo"
    dynamodb_lambda_role_name="dynamoRoleNova"
  }
}

##Setar os providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


## Setar as informações da AWS
provider "aws" {
  region     = lookup(var.awsvars,"region")
}

#Criar a tabela dynamoDB
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = lookup(var.awsvars,"dynamo_db_name")
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "email"

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table-1"
  }
}


#Criar o banco S3

resource "aws_s3_bucket" "website-bucket" {
  bucket = lookup(var.awsvars,"s3_bucket_name")
  acl    = "public-read"

    cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = [""]
  }

  website {
    index_document = "index.html"
  }
}

data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.website-bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.website-bucket.id
  policy = data.aws_iam_policy_document.allow_access.json

  depends_on = [data.aws_iam_policy_document.allow_access]
}



#Criar a lambda function
resource "aws_iam_policy" "policy_ms_svc_exc" {
  name        = "LambdaMicroserviceExecutionRole"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ],
            "Resource": aws_dynamodb_table.basic-dynamodb-table.arn  
        }
    ]
})
}

resource "aws_iam_role" "dynamoDBLambdaRole" {
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = "lambda.amazonaws.com"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    managed_policy_arns   = [
         "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
     ]
    name                  = "dynamoRoleNova"

}


resource "aws_iam_role_policy_attachment" "terraform_lambda_basic_policy" {
  role       = "${aws_iam_role.dynamoDBLambdaRole.name}"
  policy_arn = aws_iam_policy.policy_ms_svc_exc.arn
}





resource "aws_lambda_function" "lambda" {
  function_name = lookup(var.awsvars,"lambda_name")
  filename      = "apiLambda.zip"
  role          = aws_iam_role.dynamoDBLambdaRole.arn
  handler       = "index.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("apiLambda.zip")

  runtime = "nodejs14.x"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.basic-dynamodb-table.name
      REGION_NAME = lookup(var.awsvars,"region")
    }
  }
}

#Criar a API Gateway

resource "aws_apigatewayv2_api" "api_gtw" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_headers = ["*"]
    allow_methods = ["*"]
    expose_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "apigw_stage" {
  api_id = aws_apigatewayv2_api.api_gtw.id
  
  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_cloud.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "apigw_integration" {
  api_id = aws_apigatewayv2_api.api_gtw.id

  integration_uri    = aws_lambda_function.lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_gw" {
  api_id = aws_apigatewayv2_api.api_gtw.id

  route_key = "post /"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_integration.id}"
}

resource "aws_cloudwatch_log_group" "api_gw_cloud" {
  name = "/aws/apigw/${aws_apigatewayv2_api.api_gtw.name}"

  retention_in_days = 5
}

resource "aws_lambda_permission" "api_gw_lambda_perm" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gtw.execution_arn}/*/*"
}

output "api_gw_url" {
  value = format("%s/",aws_apigatewayv2_stage.apigw_stage.invoke_url)
}