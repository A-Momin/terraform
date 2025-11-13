# IAM role for EC2 instance to access ECR
resource "aws_iam_role" "ec2_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com",
      },
      Effect = "Allow",
    }],
  })
}

# Attach the AmazonEC2ContainerRegistryReadOnly (AWS Managed Policy) policy to the role
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_role_policy" "ec2_role_policies" {
  name = "ec2-role-policies"
  role = aws_iam_role.ec2_role.id

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        "Resource" : "*"
        // * will allow access to all repositories. 
        // For better security, replace * with the specific ECR ARN: 
        // "arn:aws:ecr:us-east-1:530976901147:repository/bookstore-django"
      }
    ]
  })
}

# IAM instance profile for EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "django_ec2_complete_profile"
  role = aws_iam_role.ec2_role.name
}
