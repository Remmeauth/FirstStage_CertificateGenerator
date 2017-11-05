BITCOIN_CLI="bitcoin-cli"

# Certificate configuration
echo -n "Your bitcoin address: " && read -r BITCOIN_ADDRESS
echo -n "The identifier of the transaction to be used for certificate management: " && read -r CANARY_TX
echo -n "The number of the transaction output: " && read -r CANARY_TX_OUT
echo -n "Certificate serial number: " && read -r CERTIFICATE_SERIAL
echo -n "Certificate validity in days: " && read -r VALIDITY

# Generate certificate private key
openssl genrsa -out user.key.pem 2048
# Export certificate public key
openssl rsa -outform DER -in user.key.pem -pubout > user.pub.key
# Public key hashing
PUBLIC_KEY_HASH=`openssl dgst -binary -sha256 < user.pub.key | xxd -p -c 50`
# Canary string for signature
VERIFICATION_MESSAGE=http://remme.io/certificate/$CERTIFICATE_SERIAL/$PUBLIC_KEY_HASH/$CANARY_TX/$CANARY_TX_OUT
# Create signature
SIGNATURE=`$BITCOIN_CLI signmessage $BITCOIN_ADDRESS "$VERIFICATION_MESSAGE" | sed 's/\//\\\//g'`
# Create self-signed certificate in REMME format
openssl req -key user.key.pem -new -x509 -set_serial $CERTIFICATE_SERIAL \
	-days $VALIDITY -sha256 -out user.cert.pem \
	-subj "/O=Bitcoin/CN=Remme/UID=$BITCOIN_ADDRESS/OU=$CANARY_TX/ST=$CANARY_TX_OUT/L=$SIGNATURE"
# Export the certificate to PKCS12 and X.509 formats
openssl pkcs12 -export -in user.cert.pem -inkey user.key.pem  -out certificate.p12 -passout pass:
openssl x509 -in user.cert.pem -text -noout
