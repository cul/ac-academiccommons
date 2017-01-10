# Academic Commons 3.0

## Checking out and working with a local development instance of Academic Commons 3.x.x

CURRENT RECOMMENDED VERSION OF RUBY: 2.3.3

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

5. Setup your local development DB.
   ```
   rake db:migrate
   ```

6. Start your local fedora instance.
   ```
   rake jetty:start
   ```

7. Start your local solr instance with a development core.
   ```
   solr_wrapper
   ```

8. Populate your Solr instance from Fedora
   ```
   rake ac:reindex[collection:3]
   ```
   **Note: This doesn't seem to work, but I have a feeling it has to do with the parameters.**

9. Start your local Rails app
   ```
   rails server
   ```

## Running tests
1. In order to run tests that require javascript you will need `phantomjs` installed. It can be installed using homebrew or macports.
2. Run test locally by running `RAILS_ENV=test rake ci`.


## Deploying
1. When deploying a new version of the application to test or prod, make sure to create a new tag by running:
   ```
   cap test deploy:auto_tag
   ```
   This will create a tag based on the version number (listed in `VERSION`).


## Improvements
### Making Application Faster
  1. We are only using one image from Font Awesome, instead we could be using a static image.
  2. FancyBox2 (jquery plugin) may no longer be needed, but is still referenced in view helper code.
