FROM nginx
MAINTAINER Daniel Dent (https://www.danieldent.com/)

ENV S6_OVERLAY_SHA256 65f6e4dae229f667e38177d5cad0159af31754b9b8f369096b5b7a9b4580d098
ENV ENVPLATE_SHA256 8366c3c480379dc325dea725aac86212c5f5d1bf55f5a9ef8e92375f42d55a41
ENV CLOUDFLARE_V4_SHA256 0248f5d00559a9caed08c3fad66f25f8570375c256ca3aa918dcba3378a8953c
ENV CLOUDFLARE_V6_SHA256 e7d84e6f9f8668279312a4ed836ce69cab1750d6745062c7e73d9534711d7dc7

RUN DEBIAN_FRONTEND=noninteractive apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget curl certbot \
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
    && echo $CLOUDFLARE_V4_SHA256 ips-v4 | sha256sum -c \
    && cat ips-v4 | sed -e 's/^/set_real_ip_from /' >> /etc/nginx/cloudflare.conf \
    && wget https://www.cloudflare.com/ips-v6 \
    && echo $CLOUDFLARE_V6_SHA256 ips-v6 | sha256sum -c \
    && cat ips-v6 | sed -e 's/^/set_real_ip_from /' >> /etc/nginx/cloudflare.conf \
    && echo "real_ip_header CF-Connecting-IP;" >> /etc/nginx/cloudflare.conf \
    && rm ips-v6 ips-v4 \
    && echo "---> Creating directories" \
    && mkdir -p /etc/services.d/nginx /etc/services.d/certbot \
    && echo "---> Cleaning up" \
    && DEBIAN_FRONTEND=noninteractive apt-get remove -y wget \
    && rm -Rf /var/lib/apt /var/cache/apt

COPY services.d/nginx/* /etc/services.d/nginx/
COPY services.d/certbot/* /etc/services.d/certbot/
COPY nginx.conf /etc/nginx/
COPY proxy.conf /etc/nginx/conf.d/default.conf
COPY dhparams.pem /etc/nginx/
COPY temp-setup-cert.pem /etc/nginx/temp-server-cert.pem
COPY temp-setup-key.pem /etc/nginx/temp-server-key.pem

VOLUME "/etc/letsencrypt"

ENTRYPOINT ["/init"]
CMD []
