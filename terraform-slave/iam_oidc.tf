### Generate authentication for GitHub
resource "aws_iam_openid_connect_provider" "github_oidc_slave" {
    url = "https://token.actions.githubusercontent.com"

    client_id_list = [
        "sts.amazonaws.com",
    ]

    thumbprint_list = ["6938FD4D98BAB03FAADB97B34396831E3780AEA1"]
}

### Gives permission to assume role with web identity to all resource of S3 and CloudFormation
resource "aws_iam_role" "github_oidc_role_slave" {
    name = "github_role_oidc_slave"

    assume_role_policy = jsonencode({
        Version   = "2012-10-17"
        Statement = [
          {
            Effect: "Allow",
            Principal: {
                Federated: aws_iam_openid_connect_provider.github_oidc_slave.arn
            },
            Action: "sts:AssumeRoleWithWebIdentity",
            Condition: {
                StringLike: {
                    "token.actions.githubusercontent.com:sub": "repo:FelipeSaijo/serverless-framework-AWS-runner:*"
                },
                StringEquals: {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                }
            }
          }
        ]
    })
}

resource "aws_iam_role_policy" "github_oidc_policy_slave" {
    name = "github_oidc_policy_slave"
    role = aws_iam_role.github_oidc_role_slave.id

    policy = jsonencode({
        Version: "2012-10-17",
        Statement: [
        {
            Effect: "Allow",
            Action: [
                "s3:*",
                "cloudformation:*",
                "lambda:*",
                "iam:*",
                "logs:*",
                "apigateway:*",
            ],
            Resource: "*"
        }
    ]
    })
}

output "oicd_arn_slave" {
  value = aws_iam_role.github_oidc_role_slave.arn
}
