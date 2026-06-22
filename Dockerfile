FROM nginx:stable-trixie

LABEL maintainer="Daniel Dent (https://www.danieldent.com/)"

ARG TARGETARCH
ARG S6_OVERLAY_VERSION=3.2.3.0
ARG S6_OVERLAY_AARCH64_SHA256=0952056ff913482163cc30e35b2e944b507ba1025d78f5becbb89367bf344581
ARG S6_OVERLAY_NOARCH_SHA256=b720f9d9340efc8bb07528b9743813c836e4b02f8693d90241f047998b4c53cf
ARG S6_OVERLAY_SYMLINKS_ARCH_SHA256=8e8407a0cf84fd8884cc7de52049bdce71bf3993f07cbaa2a7c8cebc9581d805
ARG S6_OVERLAY_SYMLINKS_NOARCH_SHA256=a60dc5235de3ecbcf874b9c1f18d73263ab99b289b9329aa950e8729c4789f0e
ARG S6_OVERLAY_X86_64_SHA256=a93f02882c6ed46b21e7adb5c0add86154f01236c93cd82c7d682722e8840563
ARG ENVPLATE_VERSION=1.0.3
ARG ENVPLATE_ARM64_SHA256=cd218fe4f28cf56872e0597b907d00b424d687a90eacc49b23ffe9619905d25d
ARG ENVPLATE_X86_64_SHA256=f03d729c1fa74e973f3b6db73f7d2da2bab0827068c83ac66582821c200e359b
ARG CLOUDFLARE_V4_SHA256=db746a8739a51088c27d0b3c48679d21a69aab304d4c92af3ec0e89145b0cadd
ARG CLOUDFLARE_V6_SHA256=559b5c5a20088758b4643621ae80be0a71567742ae1fe8e4ff32d1ca26297f8f

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -q; \
    apt-get dist-upgrade -y; \
    apt-get install -y --no-install-recommends bash ca-certificates curl certbot openssl pwgen xz-utils; \
    case "$TARGETARCH" in \
        amd64) \
            s6_arch="x86_64"; \
            s6_arch_sha256="$S6_OVERLAY_X86_64_SHA256"; \
            envplate_arch="x86_64"; \
            envplate_sha256="$ENVPLATE_X86_64_SHA256"; \
            ;; \
        arm64) \
            s6_arch="aarch64"; \
            s6_arch_sha256="$S6_OVERLAY_AARCH64_SHA256"; \
            envplate_arch="arm64"; \
            envplate_sha256="$ENVPLATE_ARM64_SHA256"; \
            ;; \
        *) \
            echo "Unsupported TARGETARCH: $TARGETARCH" >&2; \
            exit 1; \
            ;; \
    esac; \
    echo "---> INSTALLING s6-overlay"; \
    s6_url="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}"; \
    curl -fsSLo /tmp/s6-overlay-noarch.tar.xz "${s6_url}/s6-overlay-noarch.tar.xz"; \
    echo "${S6_OVERLAY_NOARCH_SHA256}  /tmp/s6-overlay-noarch.tar.xz" | sha256sum -c -; \
    curl -fsSLo /tmp/s6-overlay-${s6_arch}.tar.xz "${s6_url}/s6-overlay-${s6_arch}.tar.xz"; \
    echo "${s6_arch_sha256}  /tmp/s6-overlay-${s6_arch}.tar.xz" | sha256sum -c -; \
    curl -fsSLo /tmp/s6-overlay-symlinks-noarch.tar.xz "${s6_url}/s6-overlay-symlinks-noarch.tar.xz"; \
    echo "${S6_OVERLAY_SYMLINKS_NOARCH_SHA256}  /tmp/s6-overlay-symlinks-noarch.tar.xz" | sha256sum -c -; \
    curl -fsSLo /tmp/s6-overlay-symlinks-arch.tar.xz "${s6_url}/s6-overlay-symlinks-arch.tar.xz"; \
    echo "${S6_OVERLAY_SYMLINKS_ARCH_SHA256}  /tmp/s6-overlay-symlinks-arch.tar.xz" | sha256sum -c -; \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-${s6_arch}.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz; \
    echo "---> INSTALLING envplate"; \
    envplate_file="envplate_${ENVPLATE_VERSION}_Linux_${envplate_arch}.tar.gz"; \
    curl -fsSLo /tmp/${envplate_file} "https://github.com/kreuzwerker/envplate/releases/download/v${ENVPLATE_VERSION}/${envplate_file}"; \
    echo "${envplate_sha256}  /tmp/${envplate_file}" | sha256sum -c -; \
    tar -C /usr/local/bin -xzf /tmp/${envplate_file} envplate; \
    mv /usr/local/bin/envplate /usr/local/bin/ep; \
    chmod +x /usr/local/bin/ep; \
    echo "---> CREATING CloudFlare Config Snippet (not included in config by default)"; \
    echo '#Cloudflare' > /etc/nginx/cloudflare.conf; \
    curl -fsSLo ips-v4 https://www.cloudflare.com/ips-v4; \
    sort ips-v4 > ips-v4.sorted; \
    echo "${CLOUDFLARE_V4_SHA256}  ips-v4.sorted" | sha256sum -c -; \
    sed -e 's/^/set_real_ip_from /' -e 's/$/;/' ips-v4 >> /etc/nginx/cloudflare.conf; \
    curl -fsSLo ips-v6 https://www.cloudflare.com/ips-v6; \
    sort ips-v6 > ips-v6.sorted; \
    echo "${CLOUDFLARE_V6_SHA256}  ips-v6.sorted" | sha256sum -c -; \
    sed -e 's/^/set_real_ip_from /' -e 's/$/;/' ips-v6 >> /etc/nginx/cloudflare.conf; \
    rm ips-v6 ips-v4 ips-v6.sorted ips-v4.sorted; \
    echo "---> Creating directories"; \
    mkdir -p /etc/services.d/nginx /etc/services.d/certbot; \
    echo "---> Cleaning up"; \
    rm -Rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/s6-overlay*.tar.xz /tmp/envplate_*.tar.gz; \
    touch /etc/nginx/auth_part1.conf \
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
COPY temp-setup-cert.pem /etc/nginx/temp-server-cert.pem
COPY temp-setup-key.pem /etc/nginx/temp-server-key.pem

VOLUME "/etc/letsencrypt"

ENTRYPOINT ["/init"]
CMD []
