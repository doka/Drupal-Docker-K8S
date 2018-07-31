#
# Dockerfile to generate Aegir image to host Durpal & CiviCRM sites
#
# Usage:
# 1. decide on base OS image to use, and adapt this file accordingly:
#   Debian 9 based image (default):
#     Debian 9.4 + PHP 7.0 + Apache + utils
#     details in: supported-os/debian-stretch/Dockerfile
FROM wepoca/stretch-php7
#
#   Ubuntu 16.04 LTS based image:
#     Ubuntu 16.04 + PHP 7.0 + Apache + utils
#     details in: supported-os/ubuntu1604lts/Dockerfile
# FROM wepoca/lts-php7
#
# 2. build image
#   docker build -t drupal .
#
# 3. optional: tag & upload, instead "wepoca" use your Docker user
#   docker tag drupal:latest wepoca/drupal
#   docker push wepoca/drupal
#
# 4. use docker-compose.yml to start up volumes & containers to fly :)
#
# ----------------------------------
# Image & package info:
# - PHP 7.0 prepared for Drupal
# - Apache, mysql client, Postfix and utils like sudo, nano, git, wget
# - this drupal image installs and upgrades drupal
# - the particular drupal version has to be defined in docker-compose.yml
#
# ----------------------------------
#
ENV DEBIAN_FRONTEND=noninteractive

#### Apache configuration
RUN a2enmod rewrite vhost_alias
# RUN rm /etc/apache2/sites-enabled/*
# RUN rm /etc/apache2/sites-available/000-default.conf
RUN a2dissite 000-default.conf
ADD config/drupal-a2.conf /etc/apache2/sites-available/drupal-a2.conf
RUN a2ensite drupal-a2.conf

#### PHP configuration
# TODO:
# - add more config: filesize, ...
# - adapt to all PHP 7+ versions
## PHP memory limit
# memory_limit = 192M in /etc/php/7.0/cli/php.ini
# memory_limit = 192M in /etc/php/7.0/apache2/php.ini
RUN sed -i 's/memory_limit = -1/memory_limit = 192M/' /etc/php/7.0/cli/php.ini && \
    sed -i 's/memory_limit = 128M/memory_limit = 192M/' /etc/php/7.0/apache2/php.ini
# RUN echo "allow_url_fopen = On" > /usr/local/etc/php/conf.d/drupal-01.ini

#### Install Composer
# build used: 1.6.5 from 2018-05-04
ARG COMPOSER_VERSION=1.6.5
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q \
    | php -- --install-dir=/usr/local/bin --version=${COMPOSER_VERSION} --filename=composer

# Drush 8
# Pick the latest stable Dursh 8 version and install Drush via Composer
# https://github.com/drush-ops/drush/releases
ARG DRUSH_VERSION=8.1.17
RUN HOME=/ /usr/local/bin/composer global require drush/drush:$DRUSH_VERSION \
  && ln -s /.composer/vendor/drush/drush/drush /usr/local/bin/drush

# Install drupal console
RUN curl https://drupalconsole.com/installer -L -o /usr/local/bin/drupal \
  && chmod +x /usr/local/bin/drupal

#### copy entrypoint file to install/upgrade drupal
COPY scripts/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

#
WORKDIR /var/www
EXPOSE 80

#### entrypoint.sh waits for database and
# runs drupal install/upgrade as drupal user
ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
