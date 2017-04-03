########################################################
# Dockerfile for Apache + PHP + Phantom and some Extensions
########################################################
# How to run
#  - docker-compose up -d renangbarreto/apache-php5-phantomjs-docker
# How to build
#  - docker-compose build -t renangbarreto/apache-php5-phantomjs-docker -f Dockerfile .
########################################################
# SERVICES AND LIBS INSTALLED:
# - Apache2
# - PHP 5.6
# - composer (from php)
# - php-mongo extension
# - php-mongodb extension
# - php-mysql extension
# - tesseract-ocr
# - phantomjs
########################################################
# This dockerfile was created based on:
# - https://hub.docker.com/r/azukiapp/php-apache/
# - https://hub.docker.com/r/azukiapp/apache2/
########################################################

FROM azukiapp/apache2

MAINTAINER Renan Gomes <email@renangomes.com>

# Install PHP5 + Apache2 + Libs
RUN apt-get update  \
  && apt-get install -y python-software-properties software-properties-common \
  && LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php \
  && apt-get update \
  && apt-get update -qq \
  && apt-get install -y -qq nano libxml2 fontconfig tesseract-ocr tesseract-ocr-eng libfontconfig libcurl4-openssl-dev php5.6 libapache2-mod-php5.6 php5.6-cli php5.6-bcmath php5.6-bz2 php5.6-dba php5.6-imap php5.6-intl php5.6-mcrypt php5.6-soap php5.6-tidy php5.6-common php5.6-curl php5.6-gd php5.6-json php5.6-mysql php5.6-sqlite php5.6-xml php5.6-zip php5.6-mbstring php5.6-gettext php5.6-dev php5.6-pgsql \
  && sed -i -e 's/max_execution_time = 30/max_execution_time = 120/g' /etc/php/5.6/apache2/php.ini \
  && sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' /etc/php/5.6/apache2/php.ini \
  && sed -i -e 's/display_errors = Off/display_errors = On/g' /etc/php/5.6/apache2/php.ini \
  && sed -i -e 's/;always_populate_raw_post_data = -1/always_populate_raw_post_data = -1/g' /etc/php/5.6/apache2/php.ini \
  && sed -i -e 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' /etc/apache2/mods-available/dir.conf \
  && pecl install mongo-1.6.14 \
  && pecl install mongodb-1.2.6 \
  && echo "extension=mongo.so" > /etc/php/5.6/mods-available/mongo.ini \
  && echo "extension=mongodb.so" > /etc/php/5.6/mods-available/mongodb.ini \
  && echo "extension=mcrypt.so" > /etc/php/5.6/mods-available/mcrypt.ini \
  && rm -f /etc/apache2/sites-enabled/000-default.conf \
  && a2enmod headers rewrite expires filter vhost_alias ratelimit \
  && a2dismod status \
  && phpenmod mcrypt mongo mongodb curl \
  && sed -i -e "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php/5.6/apache2/php.ini \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  && sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf   \
  && apt-get clean -qq \
  && apt-get remove -y python-software-properties software-properties-common \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

# Install PhantomJs
RUN mkdir /root/phantomjs \
  && curl -LS https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 -o /root/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2 \
  && tar xvjf /root/phantomjs/phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /root/phantomjs/ \
  && chmod a+x /root/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs \
  && ln -s /root/phantomjs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs
  
# Tweaks to give Apache/PHP write permissions to the app
ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20
ENV DOCKER_MACHINE_ID 1000
ENV DOCKER_MACHINE_GID 50
RUN usermod -u ${DOCKER_MACHINE_ID} www-data && \
    usermod -G staff www-data
RUN groupmod -g $(($DOCKER_MACHINE_GID + 10000)) $(getent group $DOCKER_MACHINE_GID | cut -d: -f1)
RUN groupmod -g ${DOCKER_MACHINE_GID} staff

# Create the execution binary for the entrypoint
RUN echo "#!/bin/sh\n cd /var/www; composer --no-plugins --no-scripts install; rm -f /var/run/apache2/apache2.pid; /usr/bin/apache2-foreground" > /run/startup.sh \
    && chmod a+x /run/startup.sh

## Change the work dir the the code dir
WORKDIR /var/www

VOLUME ["/var/log/apache2", "/var/www"]

EXPOSE 80

CMD ["/bin/sh", "-c", "/run/startup.sh"]

ENTRYPOINT ["/bin/sh", "-c", "/run/startup.sh"]