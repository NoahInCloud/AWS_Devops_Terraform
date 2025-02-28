terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

###############################
# Root Certificate Generation
###############################
resource "tls_private_key" "root_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "root_cert" {
  private_key_pem = tls_private_key.root_key.private_key_pem

  subject {
    common_name = "P2SRootCert"
  }

  validity_period_hours = 8760    # 12 months
  early_renewal_hours   = 168     # Renew 7 days before expiration

  is_ca_certificate = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing"
  ]
}

###############################
# Child Certificate Generation (signed by Root)
###############################
resource "tls_private_key" "child_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "child_csr" {
  private_key_pem = tls_private_key.child_key.private_key_pem

  subject {
    common_name = "P2SChildCert"
  }
}

resource "tls_locally_signed_cert" "child_cert" {
  cert_request_pem   = tls_cert_request.child_csr.cert_request_pem
  ca_cert_pem        = tls_self_signed_cert.root_cert.cert_pem
  ca_private_key_pem = tls_private_key.root_key.private_key_pem

  validity_period_hours = 8760
  early_renewal_hours   = 168

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth"  # Corresponds to OID 1.3.6.1.5.5.7.3.2
  ]
}

###############################
# Outputs
###############################
output "root_certificate_pem" {
  description = "The PEM-encoded root certificate"
  value       = tls_self_signed_cert.root_cert.cert_pem
}

output "child_certificate_pem" {
  description = "The PEM-encoded child certificate"
  value       = tls_locally_signed_cert.child_cert.cert_pem
}
