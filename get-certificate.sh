#!/usr/bin/with-contenv sh

cd /certs

if [ -z "$SERVERNAME" ]; then
    echo "ERROR: Server name must be specified..."
else
    if simp_le --cert_key_size 2048 -d $SERVERNAME:/usr/share/nginx/html -f key.pem -f cert.pem -f fullchain.pem; then
        cp key.pem server-key.pem
        # cp cert.pem server-cert.pem
        cp fullchain.pem server-cert.pem # Nginx needs the intermediate certificate along with the server cert.
        cp fullchain.pem server-fullchain.pem
    else
        exit 1
    fi
fi

