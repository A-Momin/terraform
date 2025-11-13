

# ------------------------
# Django Secret Key
# ------------------------
resource "random_password" "django_secret_key" {
  length  = 50
  special = true
}

resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "${var.project_name}-django-secret-key"
  description             = " Stripe Secret Key for Django application"
  recovery_window_in_days = 0 # Optional: set to 0 to permanently delete immediately upon deletion

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "django_secret_key_version" {
  secret_id = aws_secretsmanager_secret.django_secret_key.id
  #   secret_string = random_password.django_secret_key.result
  secret_string = var.django_secret_key # Values are collected from Environment Variables
}

resource "aws_secretsmanager_secret" "django_stripe_secret_key" {
  name                    = "${var.project_name}-django-stripe-secret-key"
  description             = " Stripe Secret Key for Django application"
  recovery_window_in_days = 0 # Optional: set to 0 to permanently delete immediately upon deletion

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "django_stripe_secret_key_version" {
  secret_id     = aws_secretsmanager_secret.django_stripe_secret_key.id
  secret_string = var.django_stripe_secret_key # Values are collected from Environment Variables
}


resource "aws_secretsmanager_secret" "django_stripe_endpoint_secret" {
  name                    = "${var.project_name}-django-stripe-endpoint-secret"
  description             = " Stripe Secret Key for Django application"
  recovery_window_in_days = 0 # Optional: set to 0 to permanently delete immediately upon deletion

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "django_stripe_endpoint_secret_version" {
  secret_id = aws_secretsmanager_secret.django_stripe_endpoint_secret.id
  #   secret_string = random_password.django_secret_key.result
  secret_string = var.django_stripe_endpoint_secret # Values are collected from Environment Variables
}
