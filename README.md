# About this repo

This is the Docker **Drupal/Wordpress** optimized images for apache-php.

Available tags are:
- 7.3 ([7.3/Dockerfile](https://github.com/KilianMahe/docker_apache_php/blob/master/7.3/Dockerfile))
- 7.4 ([7.4/Dockerfile](https://github.com/KilianMahe/docker_apache_php/blob/master/7.4/Dockerfile))
- Latest ([7.4/Dockerfile](https://github.com/KilianMahe/docker_apache_php/blob/master/7.4/Dockerfile))

The image basically contains:

- All php libraries needed for Drupal (gd, mbstring, mcrypt, zip, soap, pdo_mysql, mysqli, xsl, opcache, calendar, intl, bcmath)
- Wp-cli for Wordpress
- Development tools for Drupal (xdebug, codesniffer, compass, less, node.js, grunt, gulp, composer, drush, phing, phpcpd, phpmetrics)
- Much more...

# Docker-compose
## Use this docker-compose.yml to create a complete development environment:

    version: '2'
    services:
      web:
        image: naroner/docker_apache_php_drupal:latest
        ports:
          - "80:80"
          - "9000:9000"
        environment:
          - SERVERNAME=example.local
          - SERVERALIAS=example2.local *.example2.local
          - BLACKFIRE_CLIENT_ID=XXXX
          - BLACKFIRE_SERVER_TOKEN=XXXX
        volumes:
          - /home/docker/projets/example/:/var/www/html/
          - /home/docker/.ssh/:/var/www/.ssh/
          - /var/www/html/.git
        links:
          - database:mysql
          - mailhog
          - solr
          - redis
          - blackfire
        tty: true

      database:
        image: mariadb
          ports:
            - "3306:3306"
          environment:
            MYSQL_ALLOW_EMPTY_PASSWORD: 'yes' 
          volumes:  
            -./mysql:/etc/mysql/conf.d

      phpmyadmin:
        image: geniousinteractive/docker-phpmyadmin
        ports:
          - "8010:80"
        environment:
          - MYSQL_ROOT_PASSWORD=
          - UPLOAD_SIZE=2G
        links:
          - database:mysql
          
      mailhog:
        image: mailhog/mailhog
        ports:
          - "1025:1025"
          - "8025:8025"
          
      redis:
        image: redis:4.0.8-alpine
        ports:
          - "6379:6379"
        command: ["redis-server", "--appendonly", "yes"]
        
      solr:
        image: solr:8
        ports:
          - "8983:8983"
        volumes:
          - ./solr/collection2/conf:/var/solr/conf
        entrypoint:
          - solr-precreate
          - collection1
          
      blackfire:
        image: blackfire/blackfire
        environment:
          - BLACKFIRE_CLIENT_ID=XXXX
          - BLACKFIRE_SERVER_TOKEN=XXXX

[Docker Hub page](https://hub.docker.com/r/naroner/docker_apache_php_drupal)
