##----------------------------------------------------------------------------
## EC2 Key Pair
##----------------------------------------------------------------------------

# Generate a new SSH key pair locally
resource "tls_private_key" "general_purpose_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the AWS key pair using the public key
resource "aws_key_pair" "general_purpose_key_pair" {
  key_name   = "general_purpose"
  public_key = tls_private_key.general_purpose_key_pair.public_key_openssh
}

# Save the private key locally (optional but useful)
resource "local_file" "private_key_pem" {
  content  = tls_private_key.general_purpose_key_pair.private_key_pem
  filename = "/Users/am/.ssh/general_purpose.pem"
}

