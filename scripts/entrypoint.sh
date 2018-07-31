#!/bin/bash

# HOSTNAME=${HOSTNAME:-`hostname -f`}
echo "Drupal | -------------------------"
echo "Drupal | Hostname: $HOSTNAME"
echo "Drupal | Drupal version: $DRUPAL_VERSION"
echo "Drupal | Database server: $DATABASE_SERVER"
echo "Drupal | Database user: $MYSQL_USER"
echo "Drupal | Database pwd: <secret>"
echo "Drupal | Database database: $MYSQL_DATABASE"
echo "Drupal | -------------------------"
echo "Drupal | Content of working directory `pwd`:"
ls -la

DRUPAL_ROOT="drupal-$DRUPAL_VERSION"
echo "Drupal | -------------------------"
if [ -d "$DRUPAL_ROOT" ]; then
  echo "Drupal | Drupal core version $DRUPAL_VERSION already installed, do nothing."
else
  echo "Drupal | New Drupal core version $DRUPAL_VERSION will be installed."

  LAST_DRUPAL=`ls /var/www | grep drupal`
  if [ ${PIPESTATUS[0]} == 0 ]; then
    # site exists with old drupal version
    LAST_VERSION=${LAST_DRUPAL##drupal-}   # strips drupal version from directory name
    echo "Drupal | Current Drupal version: $LAST_VERSION"
  else
    # new site install
    LAST_VERSION=$DRUPAL_VERSION
  fi

  echo "Drupal | -------------------------"
  echo "Drupal | Downloading Drupal $DRUPAL_VERSION into drupal-$DRUPAL_VERSION"
  # download new drupal version and depencencies with composer
  composer create-project drupal/drupal:$DRUPAL_VERSION drupal-$DRUPAL_VERSION
  echo "Drupal | Drupal $DRUPAL_VERSION downloaded into drupal-$DRUPAL_VERSION"

  if [ "$LAST_VERSION" == "$DRUPAL_VERSION" ]; then
    # new site install
    echo "Drupal | -------------------------"
    echo "Drupal | Installing new site $HOSTNAME with Drupal $DRUPAL_VERSION."

    cd $DRUPAL_ROOT
    drush -y site-install standard \
    --db-url="mysql://$MYSQL_USER:$MYSQL_PASSWORD@$DATABASE_SERVER/$MYSQL_DATABASE" \
    --account-pass="$DADMINPWD" \
    --locale=en \
    --sites-subdir=$HOSTNAME \
    --site-name=$HOSTNAME

    echo "Drupal | -------------------------"
    echo "Drupal | Setup Drupal Console."
    # https://docs.drupalconsole.com/en/getting/composer.html
    composer require drupal/console:~1.0 --prefer-dist --optimize-autoloader
    # drupal init
    cd sites/$HOSTNAME
    drupal init \
      --destination="/var/www/$DRUPAL_ROOT/console/" \
      --uri="http://$HOSTNAME" \
      --no-interaction

    echo "Drupal | -------------------------"
    echo "Drupal | Setting basic permissions on files."
    # basic permissions, TBC!!!
    cd /var/www
    chown -R www-data:www-data $DRUPAL_ROOT/sites/$HOSTNAME
    ls -la $DRUPAL_ROOT/sites
    echo "Drupal | -------------------------"
    echo "Drupal | New site ready at http://$HOSTNAME"

  else
    # upgrade existing site to new drupal core version
    echo "Drupal | -------------------------"
    echo "Drupal | Upgrading site $HOSTNAME to Drupal $DRUPAL_VERSION."

    # copy site directory and sites.php into new drupal root
    cp -a $LAST_DRUPAL/sites/$HOSTNAME $DRUPAL_ROOT/sites
    cp -a $LAST_DRUPAL/sites/sites.php $DRUPAL_ROOT/sites
    # clean up old site
    chmod u+w $LAST_DRUPAL/sites/$HOSTNAME
    rm -rf $LAST_DRUPAL

    echo "Drupal | -------------------------"
    echo "Drupal | upgrading the database"
    cd $DRUPAL_ROOT/sites/$HOSTNAME
    drush updatedb -y

    echo "Drupal | -------------------------"
    echo "Drupal | Site http://$HOSTNAME upgraded."
  fi

fi

# TODO:
# - set trusted host settings https://www.drupal.org/node/1992030
# - more flexible drupal version attributes, like  ~8.4 nor ^8.5.1

# Run whatever is the Docker CMD
echo "Drupal | -------------------------"
echo "Drupal | Running Docker Command '$@' ..."
echo "Drupal | -------------------------"
exec "$@"
