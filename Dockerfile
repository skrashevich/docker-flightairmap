# syntax=docker/dockerfile:1.6

ARG DEBIAN_FRONTEND=noninteractive
FROM debian:stable-slim
ARG DEBIAN_FRONTEND
ENV BASESTATIONPORT="30003" \
    FAM_BINGKEY="" \
    FAM_BITLYACCESSTOKENAPI="" \
    FAM_BRITISHAIRWAYSAPIKEY="" \
    FAM_CORSPROXY="https://galvanize-cors-proxy.herokuapp.com/" \
    FAM_FLIGHTAWAREPASSWORD="" \
    FAM_FLIGHTAWAREUSERNAME="" \
    FAM_GEOID_SOURCE="egm96-15" \
    FAM_GLOBALSITENAME="My FlightAirMap Site" \
    FAM_GOOGLEKEY="" \
    FAM_GRAPHHOPPERAPIKEY="" \
    FAM_HEREAPPCODE="" \
    FAM_HEREAPPID="" \
    FAM_LANGUAGE="EN" \
    FAM_LATITUDECENTER="46.38" \
    FAM_LIVEZOOM="9" \
    FAM_LONGITUDECENTER="5.29" \
    FAM_LUFTHANSAKEY="" \
    FAM_LUFTHANSASECRET="" \
    FAM_MAPBOXID="examples.map-i86nkdio" \
    FAM_MAPBOXTOKEN="" \
    FAM_MAPMATCHINGSOURCE="fam" \
    FAM_MAPPROVIDER="OpenStreetMap" \
    FAM_MAPQUESTKEY="" \
    FAM_METARSOURCE="" \
    FAM_NOTAMSOURCE="" \
    FAM_OPENWEATHERMAPKEY="" \
    FAM_SAILAWAYEMAIL="" \
    FAM_SAILAWAYKEY="" \
    FAM_SAILAWAYPASSWORD="" \
    FAM_SQUAWK_COUNTRY="EU" \
    MYSQLDATABASE=flightairmap \
    MYSQLUSERNAME=flightairmap \
    MYSQLPORT=3306 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    TZ=UTC \
    WEBUSER=flightairmap

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Prepare apt for buildkit cache
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
  && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,id=${TARGETARCH},target=/var/cache/apt,sharing=locked --mount=type=cache,id=${TARGETARCH},target=/var/lib/apt,sharing=locked \
    set -x && \
    apt update && \
    apt install -y --no-install-recommends --no-install-suggests \
        ca-certificates \
        curl \
        file \
        git \
        html2text \
        jq \
        locales \
        procps \
        socat \
        wget \
        pwgen \
        && \
    useradd -d "/home/${WEBUSER}" -m -r -U "${WEBUSER}" && \
    echo "========== Setup locales ==========" && \
    echo "en_US ISO-8859-1" >> /etc/locale.gen && \
    echo "de_DE ISO-8859-1" >> /etc/locale.gen && \
    echo "es_ES ISO-8859-1" >> /etc/locale.gen && \
    echo "fr_FR ISO-8859-1" >> /etc/locale.gen && \
    echo "ru_RU ISO-8859-1" >> /etc/locale.gen && \
    locale-gen && \
    echo "========== Deploy php7 ==========" && \
    apt install -y --no-install-recommends --no-install-suggests \
        php \
        php-curl \
        php-fpm \
        php-gd \
        php-gettext \
        php-json \
        php-mysql \
        php-xml \
        php-zip \
        && \
    sed -i '/;error_log/c\error_log = /proc/self/fd/2' /etc/php/7.3/fpm/php-fpm.conf && \
    mkdir -p /run/php && \
    rm -vrf /etc/php/7.3/fpm/pool.d/* && \
    echo "========== Deploy nginx ==========" && \
    apt-get install -y --no-install-recommends \
        nginx-light && \
    rm -vf /etc/nginx/conf.d/default.conf && \
    rm -vrf /var/www/* && \
    usermod -aG www-data "${WEBUSER}" && \
    echo "========== Deploy MariaDB ==========" && \
    apt-get install -y --no-install-recommends \
        mariadb-server && \
    mkdir -p /run/mysqld && \
    chown -vR mysql:mysql /run/mysqld && \
    echo "========== Deploy FlightAirMap ==========" && \
    git clone --recursive https://github.com/Ysurac/FlightAirMap /var/www/flightairmap/htdocs && \
    pushd /var/www/flightairmap/htdocs && \
    cp -v /var/www/flightairmap/htdocs/install/flightairmap-nginx-conf.include /etc/nginx/flightairmap-nginx-conf.include && \
    chown -vR "${WEBUSER}":"${WEBUSER}" /var/www/flightairmap && \
    git log | head -1 | tr -s " " "_" | tee /VERSION || true && \
    rm -rf /var/www/flightairmap/htdocs/.git && \
    echo "========== Deploy s6-overlay ==========" && \
    apt-get install --no-install-recommends -y gnupg && \
    wget -q -O - https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh &&  \
    apt-get remove -y gnupg && \
    echo "========== Clean up ==========" && \
    apt remove -y \
        file \
        git \
        && \
    apt-get autoremove -y && \
    rm -rf /tmp/* /src

# Copy config files
COPY etc/ /etc/

ENTRYPOINT [ "/init" ]

EXPOSE 80
