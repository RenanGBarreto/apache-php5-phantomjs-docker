# Docker images for common apache and PHP apps
Docker images with apache 2, PHP 5.6, php mongo extensions, phantomJS and tesseract OCR.

## Software installed:
- Apache2
- PHP 5.6
- composer (from php)
- php-mongo extension
- php-mongodb extension
- php-mysql extension
- tesseract-ocr
- phantomjs

## How to run
``` docker-compose up -d renangbarreto/apache-php5-phantomjs-docker ```

## How to build
``` docker-compose build -t renangbarreto/apache-php5-phantomjs-docker -f Dockerfile . ```
