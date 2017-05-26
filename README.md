# Academic Commons 3.0

## Checking out and working with a local development instance

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

8. Start your local Rails app
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

2. Start Solr (Leave this command running in the background.)
   ```
   solr_wrapper
   ```
   
3. Load the collection and one item into Fedora.
   ```
   rake ac:populate_solr
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
