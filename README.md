# Authentify

This application is using:
* Sinatra framework
* Postgresql
* Sequel as ORM


## Database

### Create database
Before running the migrations we need to create a database.

Connecto to MariaDB and run the following command.
```
CREATE DATABASE [database];
CREATE DATABASE user_auth;
```

### Configure database
There is an example DB configuration file `database.yml.example` placed in `config` folder.

* Create real configuration file from the example
  * `cp database.yml.example database.yml`
* Change the values in the configuration file

### Run migrations
```
sequel config/database.yml -e [env] -E -t -m db/migrations
sequel config/database.yml -e development -E -t -m db/migrations
```

### How to create a migration file
In order to change the database schema, create a file in `db/migrations` folder with name like `[timestamp]_[action].rb`. E.g. `001_create_users.rb`.

## Run the application
```
bundle exec rackup
```
