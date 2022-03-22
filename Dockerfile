FROM nginx
MAINTAINER Daniel Dent (https://www.danieldent.com/)

ENV S6_OVERLAY_SHA256 65f6e4dae229f667e38177d5cad0159af31754b9b8f369096b5b7a9b4580d098
ENV ENVPLATE_SHA256 8366c3c480379dc325dea725aac86212c5f5d1bf55f5a9ef8e92375f42d55a41
ENV CLOUDFLARE_V4_SHA256 db746a8739a51088c27d0b3c48679d21a69aab304d4c92af3ec0e89145b0cadd
ENV CLOUDFLARE_V6_SHA256 559b5c5a20088758b4643621ae80be0a71567742ae1fe8e4ff32d1ca26297f8f

ARG TARGETARCH


RUN DEBIAN_FRONTEND=noninteractive apt-get update -q 
RUN DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget curl certbot pwgen 
RUN echo "---> INSTALLING s6-overlay" 
RUN if [ "$TARGETARCH" -eq "amd64" ]; then ARCH="amd64"; else ARCH="aarch64"; fi \
    && wget https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-$ARCH.tar.gz \
    && tar xzf s6-overlay-$ARCH.tar.gz -C / \
    && rm s6-overlay-$ARCH.tar.gz 
RUN echo "---> INSTALLING envplate" 
RUN if [ "$TARGETARCH" -eq "amd64" ]; then ARCH="x_86_64"; else ARCH="arm64"; fi \
    &&  curl -L  -o envplate https://github.com/kreuzwerker/envplate/releases/download/v1.0.2/envplate_1.0.2_Linux_$ARCH.tar.gz
RUN tar -zxvf envplate
RUN find . -name envplate -exec mv {} /usr/local/bin/ep \; 
RUN chmod a+x /usr/local/bin/ep
RUN echo "---> CREATING CloudFlare Config Snippet (not included in config by default)" 
RUN echo '#Cloudflare' > /etc/nginx/cloudflare.conf 
RUN wget https://www.cloudflare.com/ips-v4 
RUN sort ips-v4 > ips-v4.sorted 
RUN echo $CLOUDFLARE_V4_SHA256 ips-v4.sorted | sha256sum -c     
RUN cat ips-v4 | sed -e 's/^/set_real_ip_from /' -e 's/$/;/' >> /etc/nginx/cloudflare.conf 
RUN wget https://www.cloudflare.com/ips-v6 
RUN sort ips-v6 > ips-v6.sorted 
RUN echo $CLOUDFLARE_V6_SHA256 ips-v6.sorted | sha256sum -c 
RUN cat ips-v6 | sed -e 's/^/set_real_ip_from /' -e 's/$/;/' >> /etc/nginx/cloudflare.conf 
RUN rm ips-v6 ips-v4 ips-v6.sorted ips-v4.sorted 
RUN echo "---> Creating directories" 
RUN mkdir -p /etc/services.d/nginx /etc/services.d/certbot 
RUN echo "---> Cleaning up" 
RUN DEBIAN_FRONTEND=noninteractive apt-get remove -y wget 
RUN rm -Rf /var/lib/apt /var/cache/apt 
RUN touch /etc/nginx/auth_part1.conf \
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
