FROM nginx
MAINTAINER Daniel Dent (https://www.danieldent.com/)

ENV S6_OVERLAY_SHA256 65f6e4dae229f667e38177d5cad0159af31754b9b8f369096b5b7a9b4580d098
ENV ENVPLATE_SHA256 8366c3c480379dc325dea725aac86212c5f5d1bf55f5a9ef8e92375f42d55a41
ENV CLOUDFLARE_V4_SHA256 db746a8739a51088c27d0b3c48679d21a69aab304d4c92af3ec0e89145b0cadd
ENV CLOUDFLARE_V6_SHA256 559b5c5a20088758b4643621ae80be0a71567742ae1fe8e4ff32d1ca26297f8f

RUN DEBIAN_FRONTEND=noninteractive apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget curl certbot pwgen \
    && echo "---> INSTALLING s6-overlay" \
    && wget https://github.com/just-containers/s6-overlay/releases/download/v1.17.0.0/s6-overlay-amd64.tar.gz \
    && echo $S6_OVERLAY_SHA256 s6-overlay-amd64.tar.gz | sha256sum -c \
    && tar xzf s6-overlay-amd64.tar.gz -C / \
    && rm s6-overlay-amd64.tar.gz \
    && echo "---> INSTALLING envplate" \
    && wget https://github.com/kreuzwerker/envplate/releases/download/v0.0.8/ep-linux \
    && echo $ENVPLATE_SHA256 ep-linux | sha256sum -c \
    && chmod +x ep-linux \
    && mv ep-linux /usr/local/bin/ep \
    && echo "---> CREATING CloudFlare Config Snippet (not included in config by default)" \
    && echo '#Cloudflare' > /etc/nginx/cloudflare.conf \
    && wget https://www.cloudflare.com/ips-v4 \
    && sort ips-v4 > ips-v4.sorted \
    && echo $CLOUDFLARE_V4_SHA256 ips-v4.sorted | sha256sum -c \
    && cat ips-v4 | sed -e 's/^/set_real_ip_from /' -e 's/$/;/' >> /etc/nginx/cloudflare.conf \
    && wget https://www.cloudflare.com/ips-v6 \
    && sort ips-v6 > ips-v6.sorted \
    && echo $CLOUDFLARE_V6_SHA256 ips-v6.sorted | sha256sum -c \
    && cat ips-v6 | sed -e 's/^/set_real_ip_from /' -e 's/$/;/' >> /etc/nginx/cloudflare.conf \
    && rm ips-v6 ips-v4 ips-v6.sorted ips-v4.sorted \
    && echo "---> Creating directories" \
    && mkdir -p /etc/services.d/nginx /etc/services.d/certbot \
    && echo "---> Cleaning up" \
    && DEBIAN_FRONTEND=noninteractive apt-get remove -y wget \
    && rm -Rf /var/lib/apt /var/cache/apt \
    && touch /etc/nginx/auth_part1.conf \
             /etc/nginx/auth_part2.conf \
             /etc/nginx/request_size.conf \
             /etc/nginx/main_location.conf \
             /etc/nginx/trusted_proxies.conf \
             /tmp/htpasswd

COPY services.d/nginx/* /etc/services.d/nginx/
COPY services.d/certbot/* /etc/services.d/certbot/
COPY nginx.conf security_headers.conf hsts.conf /etc/nginx/
COPY proxy.conf /etc/nginx/conf.d/default.conf
COPY auth_part*.conf /root/
COPY dhparams.pem /etc/nginx/
COPY temp-setup-cert.pem /etc/nginx/temp-server-cert.pem
COPY temp-setup-key.pem /etc/nginx/temp-server-key.pem

VOLUME "/etc/letsencrypt"

ENTRYPOINT ["/init"]
CMD []
