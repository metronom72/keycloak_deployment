#!/usr/bin/env bash
#
# generate-certs.sh
#
# A simple script to generate a self-signed certificate and private key
# using OpenSSL for development or testing.
#
# Usage:
#   chmod +x generate-certs.sh
#   ./generate-certs.sh
#
# After running, you will have:
#   - tls.crt (the self-signed certificate)
#   - tls.key (the private key)
#
# NOTE: For production, get certificates from a CA (e.g. Let's Encrypt).

# Exit immediately if any command fails
set -e

# Edit these variables as you like:
CERT_NAME="tls"                   # Base name (will produce tls.crt + tls.key)
KEY_SIZE=2048                     # RSA key size: 2048 or 4096
DAYS_VALID=365                    # Validity in days
SUBJECT="/C=US/ST=CA/L=SomeCity/O=SomeOrg/OU=Dev/CN=localhost"

echo "Generating a ${KEY_SIZE}-bit RSA key and a self-signed certificate valid for ${DAYS_VALID} days..."
echo "Subject: ${SUBJECT}"

# Generate private key
openssl genrsa -out "${CERT_NAME}.key" "${KEY_SIZE}"

# Generate a certificate signing request (CSR)
openssl req -new -key "${CERT_NAME}.key" -subj "${SUBJECT}" -out "${CERT_NAME}.csr"

# Generate self-signed certificate
openssl x509 -req -in "${CERT_NAME}.csr" \
  -signkey "${CERT_NAME}.key" \
  -sha256 -days "${DAYS_VALID}" \
  -out "${CERT_NAME}.crt"

# Clean up the CSR if you don't need to keep it
rm -f "${CERT_NAME}.csr"

echo
echo "Created files:"
echo "  - ${CERT_NAME}.crt (Self-signed Certificate)"
echo "  - ${CERT_NAME}.key (Private Key)"
echo
echo "Done!"
