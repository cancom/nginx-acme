FROM nginx:1.23.2
LABEL maintainer="Sina Anvari <sina.anvari@cancom.de>"

# Install cron
RUN apt-get update && apt-get install -y --no-install-recommends \
  cron \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && service cron start

# Install the latest version of acme.sh
ENV LE_WORKING_DIR=/acme.sh
ENV LE_CONFIG_HOME=/acmecerts
RUN curl https://get.acme.sh | sh -s -- no-cron --no-profile \
  && $LE_WORKING_DIR/acme.sh --set-default-ca --server letsencrypt \
  && ln -s $LE_WORKING_DIR/acme.sh /usr/local/bin/acme.sh

# Create new directories and set correct permissions.
RUN mkdir -p /var/www/_letsencrypt \
  && chown www-data:www-data /var/www/_letsencrypt

RUN rm -rf /etc/nginx
COPY files/nginx-conf /etc/nginx
COPY files/manage-vhosts.sh /root/
COPY files/logrotate /etc/logrotate.d/nginx-acme
COPY files/acme-cron-generator.sh /docker-entrypoint.d/99-acme-cron-generator.sh
RUN ln -s /root/manage-vhosts.sh /usr/local/bin/manage-vhosts
