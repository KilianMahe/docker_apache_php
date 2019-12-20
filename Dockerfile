# Pull base image.
FROM php:7.3-apache
COPY config/php.ini /usr/local/etc/php/

RUN apt-get clean && apt-get update && apt-get install --fix-missing wget -y
RUN apt-get install -y --fix-missing gnupg
RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN cd /tmp && wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg

RUN apt-get clean && apt-get update && apt-get install -y --fix-missing \
  ruby-dev \
  rubygems \
  graphviz \
  sudo \
  git \
  vim \
  gnupg2 \
  imagemagick \
  libmagickwand-dev \
  memcached \
  libmemcached-tools \
  libmemcached-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  libxml2-dev \
  libxslt1-dev \
  mysql-client \
  zlib1g-dev \
  libzip-dev \
  zip \
  wget \
  linux-libc-dev \
  libyaml-dev \
  apt-transport-https \
  zlib1g-dev \
  libicu-dev \
  libpq-dev \
  bash-completion \
  libldap2-dev \
  automake \
  libxpm-dev \
  libssl-dev

# postgresql-client-9.5
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list && apt-get update && apt-get install -y postgresql-client-9.5

# Install memcached for PHP 7
RUN cd /tmp && git clone https://github.com/php-memcached-dev/php-memcached.git
RUN cd /tmp/php-memcached && phpize && ./configure --disable-memcached-sasl && make && make install

RUN apt-get install pkg-config libmagickwand-dev -y

COPY docker-php-ext-install /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ext-install
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/

RUN docker-php-source extract
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ --with-xpm-dir=/usr/include/ --enable-gd-jis-conv

RUN pecl install imagick-3.4.3

# Install xdebug. We need at least 2.4 version to have PHP 7 support.
RUN cd /tmp/ && wget https://xdebug.org/files/xdebug-2.7.0RC2.tgz && tar -xvzf xdebug-2.7.0RC2.tgz && cd xdebug-2.7.0RC2/ && phpize && ./configure --enable-xdebug --with-php-config=/usr/local/bin/php-config && make && make install
RUN cd /tmp/xdebug-2.7.0RC2 && cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20180731/
RUN echo 'zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20180731/xdebug.so' >> /usr/local/etc/php/php.ini
RUN touch /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo xdebug.remote_enable=1 >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo xdebug.remote_autostart=0 >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo xdebug.remote_connect_back=1 >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo xdebug.remote_port=9000 >> /usr/local/etc/php/conf.d/xdebug.ini &&\
  echo xdebug.remote_log=/tmp/php5-xdebug.log >> /usr/local/etc/php/conf.d/xdebug.ini

RUN docker-php-ext-install \
  opcache \
  gd \
  mbstring \
  zip \
  soap \
  pdo_mysql \
  mysqli \
  xsl \
  calendar \
  intl \
  exif \
  pgsql \
  pdo_pgsql \
  ftp \
  bcmath \
  ldap

RUN docker-php-ext-enable \
  opcache \
  imagick \
  gd \
  mbstring \
  zip \
  soap \
  pdo_mysql \
  mysqli \
  xsl \
  calendar \
  intl \
  exif \
  pgsql \
  pdo_pgsql \
  ftp \
  bcmath \
  ldap

RUN pecl install yaml-2.0.4 && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/ext-yaml.ini

RUN pecl install -o -f redis \
&&  rm -rf /tmp/pear \
&&  echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

RUN apt-get install -y libmcrypt-dev && \
    pecl install mcrypt-1.0.2 && \
    docker-php-ext-enable mcrypt

COPY core/memcached.conf /etc/memcached.conf

# SASS and Compass installation
RUN gem install compass

# Installation node.js
RUN wget -qO- https://deb.nodesource.com/setup_8.x | sudo bash -
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install -y nodejs

# Installation of LESS
RUN npm update -g npm@latest && \
npm install -g less && npm install -g less-plugin-clean-css

# Installation of Grunt
RUN npm install -g grunt-cli

# Installation of Gulp
RUN npm install -g gulp

# Installation of Bower
RUN npm install -g bower

# Installation of Composer
RUN cd /usr/src && curl -sS http://getcomposer.org/installer | php;
RUN cd /usr/src && mv composer.phar /usr/bin/composer

# Installation of drush
RUN git clone https://github.com/drush-ops/drush.git /usr/local/src/drush
RUN cd /usr/local/src/drush && git checkout 8.1.15
RUN ln -s /usr/local/src/drush/drush /usr/bin/drush
RUN cd /usr/local/src/drush && composer update && composer install

# Installation of WP-CLI
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

RUN rm -rf /var/www/html && \
  mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html && \
  chown -R www-data:www-data /var/lock/apache2 /var/run/apache2 /var/log/apache2 /var/www/html

# Installation of PHP_CodeSniffer with Drupal coding standards.
# See https://www.drupal.org/node/1419988#coder-composer
RUN composer global require drupal/coder
RUN ln -s ~/.composer/vendor/bin/phpcs /usr/local/bin
RUN ln -s ~/.composer/vendor/bin/phpcbf /usr/local/bin
RUN phpcs --config-set installed_paths ~/.composer/vendor/drupal/coder/coder_sniffer

# # Installation of Symfony console autocomplete
# RUN composer global require bamarni/symfony-console-autocomplete

# installation of ssmtp
RUN DEBIAN_FRONTEND=noninteractive apt-get install --fix-missing -y ssmtp && rm -r /var/lib/apt/lists/*
ADD core/ssmtp.conf /etc/ssmtp/ssmtp.conf
ADD core/php-smtp.ini /usr/local/etc/php/conf.d/php-smtp.ini

COPY config/apache2.conf /etc/apache2
COPY core/envvars /etc/apache2
COPY core/other-vhosts-access-log.conf /etc/apache2/conf-enabled/
RUN rm /etc/apache2/sites-enabled/000-default.conf

RUN a2enmod rewrite expires && service apache2 restart

# Install Drupal Console for Drupal 8
RUN curl https://drupalconsole.com/installer -L -o drupal.phar && mv drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal

# Install Nano
RUN echo deb http://http.debian.net/debian jessie main >> /etc/apt/sources.list
RUN apt-get update && apt-get install nano -y
RUN apt-get install pv -y

# Install RVM
RUN curl -sSL https://rvm.io/mpapis.asc | gpg2 --no-tty --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --no-tty --import -
RUN \curl -L https://get.rvm.io | rvm_path=/opt/rvm bash -s stable
RUN /bin/bash -l -c "/opt/rvm/bin/rvm requirements"

# Add blackFire.io
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Our apache volume
VOLUME /var/www/html

# create directory for ssh keys
RUN mkdir /var/www/.ssh/
RUN chown -R www-data:www-data /var/www/
RUN chmod -R 600 /var/www/.ssh/

# Set timezone to Europe/Paris
RUN echo "Europe/Paris" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# ADD BASHRC CONFIG
COPY config/bashrc /root/
RUN mv /root/bashrc /root/.bashrc

# Expose 80 for apache, 9000 for xdebug
EXPOSE 80 9000

# Set a custom entrypoint.
COPY core/docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
