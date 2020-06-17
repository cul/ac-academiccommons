# Academic Commons 4.0

[![Build Status](https://travis-ci.org/cul/ac-academiccommons.svg?branch=master)](https://travis-ci.org/cul/ac-academiccommons) [![Coverage Status](https://coveralls.io/repos/github/cul/ac-academiccommons/badge.svg?branch=master)](https://coveralls.io/github/cul/ac-academiccommons?branch=master)

## Checking out and working with a local development instance

CURRENT RECOMMENDED VERSION OF RUBY: 2.5.3

1. Clone the repository to a location of your choosing
   ```
   git clone git@github.com:cul/ac-academiccommons.git
   ```

2. Checkout the current development branch
   ```
   git checkout {branch}
   ```

3. Create local config files from templates
   ```
   cp config/database.template.yml config/database.yml
   cp config/solr.template.yml config/solr.yml
   cp config/fedora.template.yml config/fedora.yml
   cp config/secrets.template.yml config/secrets.yml
   cp config/blacklight.template.yml config/blacklight.yml
   ```

4. Install any needed gems using Bundler
   ```
   bundle install
   ```

5. Install required Javascript libraries using Yarn
    ```
    brew install yarn
    yarn
    ```

6. Setup your local development DB.
   ```
   rake db:migrate
   ```

7. Start your local fedora instance.
   ```
   rake jetty:start
   ```

8. Start your local solr instance with a development core. (Leave this command running in the background)
   ```
   solr_wrapper
   ```

9. Start your local Rails app
   ```
   rails server
   ```

## Populating your development instance with items
If you need an object in AC to do further testing and development, add a collection and item with the following instructions.

1. Clean out Solr and Fedora (only necessary if previously loaded items)
   ```
   solr_wrapper clean
   rake jetty:clean
   ```

2. Start Fedora
   ```
   rake jetty:start
   ```

2. Start Solr (Leave this command running in the background)
   ```
   solr_wrapper
   ```

3. Load the collection and one item into Fedora.
   ```
   rake ac:populate_solr
   ```

## Authentication/Authorization in development
If you would like to see pages that require authentication follow the steps below.

1. Seed your development database with two users. ONLY USE THIS IN DEVELOPMENT.
   ```
   rake db:seed
   ```

2. Log in as one of the users that was just added. When you click the `log in` link, you will be prompted for a uni.

   For administrative privileges, log in as `ta123`.

   For a user without administrative privileges, log in as `tu123`.

## Rubocop
We use the `rubocul` to centralize our rubocop config and share it among repos. In order to regenerate `.rubocop_todo` please use the following command. Using the following command creates a rubocop_todo configuration that only excludes files from cops instead of enabling/disabling cops and changing configuration values.
```
rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

## Running tests
1. In order to run tests that require javascript you will might need `chrome` installed (needs to be tested).
2. Run tests locally by running `rake ci`.
3. Run tests and rubocop by running `rake` (this is the task used on each travis build).

## Deploying
1. When deploying a new version of the application to test or prod, make sure to create a new tag by running:
   ```
   cap test cul:auto_tag
   ```
   This will create a tag based on the version number (listed in `VERSION`).

## API v1
Documentation for the Academic Commons API can be found at `/api/v1/swagger_doc`. To view documentation in a swagger GUI, the following url has to be created:
```
http://petstore.swagger.io/?url=#{root_url}/api/v1/swagger_doc

example: http://petstore.swagger.io/?url=http://www.example.com/api/v1/swagger_doc
```

## Helpful things to know
### Authentication/Authorization
We are using cul_omniauth to provide Columbia CAS login (authentication). In addition, we are using CanCanCan for authorization of specific tasks. Right now, we just have one role, and that's 'admin.' Later, we might want a more complex permissions structure, but for right now this fits our needs. Any page that requires authentication will redirect the user to the Columbia CAS login page. If a json response is requested, the user is not redirected.
