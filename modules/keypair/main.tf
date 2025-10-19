resource "tls_private_key" "generate" {
  algorithm = var.key_info.algorithm
  rsa_bits  = var.key_info.rsa_bits
}

resource "aws_key_pair" "public_key" {
  public_key = tls_private_key.generate.public_key_openssh
  key_name   = "${var.region_name}-${lower(tls_private_key.generate.algorithm)}-key"
}

resource "local_file" "private_key_file" {
  content              = tls_private_key.generate.private_key_pem
  filename             = "${path.module}/id_ed25519"
  file_permission      = "0600"
  directory_permission = "0700"
}
