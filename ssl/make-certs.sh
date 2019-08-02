read -p "This script creates and possibly overwrites SSL certs in the current directory ... Continue? [y,N] " answer
case $answer in
    y|Y) ;;
    *)   echo "Canceled." & exit 0 ;;
esac

# Carto Builder
openssl \
  req -x509 \
  -newkey rsa:4096 \
  -keyout key.carto.lan.pem \
  -out insecure-self-signed-cert.carto.lan.pem \
  -days 3650 \
  -nodes \
  -subj '/C=US/ST=Tennessee/L=Nashville/O=Starter/OU=Super Duper Cool People/CN=carto.lan/emailAddress=admin@example.org'
# Carto Builder (with org name in subdomain)
openssl \
  req -x509 \
  -newkey rsa:4096 \
  -keyout key.wildcard.carto.lan.pem \
  -out insecure-self-signed-cert.wildcard.carto.lan.pem \
  -days 3650 \
  -nodes \
  -subj '/C=US/ST=Tennessee/L=Nashville/O=Starter/OU=Super Duper Cool People/CN=*.carto.lan/emailAddress=admin@example.org'
  # Carto Maps API (with user name in subdomain)
openssl \
  req -x509 \
  -newkey rsa:4096 \
  -keyout key.wildcard.mapsapi.lan.pem \
  -out insecure-self-signed-cert.wildcard.mapsapi.lan.pem \
  -days 3650 \
  -nodes \
  -subj '/C=US/ST=Tennessee/L=Nashville/O=Starter/OU=Super Duper Cool People/CN=*.mapsapi.lan/emailAddress=admin@example.org'
# Carto SQL API (with user name in subdomain)
openssl \
  req -x509 \
  -newkey rsa:4096 \
  -keyout key.wildcard.sqlapi.lan.pem \
  -out insecure-self-signed-cert.wildcard.sqlapi.lan.pem \
  -days 3650 \
  -nodes \
  -subj '/C=US/ST=Tennessee/L=Nashville/O=Starter/OU=Super Duper Cool People/CN=*.sqlapi.lan/emailAddress=admin@example.org'

echo "Done."
