# Academic Commons 4.0

[![Build Status](https://travis-ci.org/cul/ac-academiccommons.svg?branch=master)](https://travis-ci.org/cul/ac-academiccommons) [![Coverage Status](https://coveralls.io/repos/github/cul/ac-academiccommons/badge.svg?branch=master)](https://coveralls.io/github/cul/ac-academiccommons?branch=master)

## Checking out and working with a local development instance

Current recommended version of Ruby is specified in `.ruby-version`.

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
   bin/copy-config-template-files
   ```

4. Create encrypted credentials files for development and test environments
   ```
   bundle exec rake ac:templated_credentials:add_all
   ```

5. Install any needed gems using Bundler
   ```
   bundle install
   ```

6. Install required Javascript libraries using Yarn
    ```
    brew install yarn
    yarn
    ```

7. Setup your local development DB.
   ```
   bundle exec rake db:migrate
   ```

8. Start your local fedora and solr instances. Docker must be running on your computer.
   ```
   bundle exec rake ac:docker:start
   ```

9. In a separate terminal window, start the vite dev server for faster asset compilation.
   ```
   bin/vite dev
   ```

10. Start your local Rails app
   ```
   rails server
   ```

## Populating your development instance with items
If you need an object in AC to do further testing and development, add an item with the following instructions.

1. Stop Fedora and Solr
   ```
   bundle exec rake ac:docker:stop
   ```

2. Clean out Solr and Fedora (only necessary if previously loaded items)
   ```
   bundle exec rake ac:docker:delete_volumes
   ```

3. Start Fedora and Solr
   ```
   bundle exec rake ac:docker:start
   ```

4. Load the collection and one item into Fedora.
   ```
   bundle exec rake ac:populate_solr
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
We use the `rubocul` gem to centralize our rubocop config and share it among repos. In order to regenerate `.rubocop_todo` please use the following command. Using the following command creates a rubocop_todo configuration that only excludes files from cops instead of enabling/disabling cops and changing configuration values.
```
rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

To run the cops, you can use the executable:
```
bin/rubocop
```

The cops also run in the default rake task, `bundle exec rake`.

## Running tests
1. In order to run tests that require javascript you might need `chrome` installed (needs to be tested).
2. Run tests locally by running `rake ci`.
3. Run tests and rubocop by running `rake` (this is the task used on each travis build).

## Deploying
1. When deploying a new version of the application to test or prod, make sure to create a new tag by running:
   ```
   cap test cul:auto_tag
   ```
   This will create a tag based on the version number (listed in `VERSION`).

## Editing encrypted credentials
### In development
Academic Commons uses Rails credentials to encrypt and load sensative information. During local development, an encrypted `development.enc.yml` file is used
with dummy values loaded from the local template file: `config/development_credentials_template.yml`. The encrypted credentials are created from the template using the following rake task:
```
   bundle exec rake ac:templated_credentials:add_all
```

To edit the values during development, simply edit the `config/local_credentials.yml` file and re-run the rake task.

### In deployed environments
To edit these values in deployed environments, you must SSH into the host and edit the credentials file there using the provided Rails task:
```
EDITOR=vim bin/rails credentials --environment=academiccommons_{dev|test|prod}
```

The master keys for deployed environments are only stored on the respective servers in the deployment's shared directory.

Make sure when you are editing the credentials that you include the environment flag and set it properly! You can also set a different editor than vim if you would like.

## API v1
Documentation for the Academic Commons API can be found at `/api/v1/swagger_doc`. To view documentation in a swagger GUI, the following url has to be created:
```
http://petstore.swagger.io/?url=#{root_url}/api/v1/swagger_doc

example: http://petstore.swagger.io/?url=http://www.example.com/api/v1/swagger_doc
```

## Helpful things to know
### Authentication/Authorization
We are using cul_omniauth to provide Columbia CAS login (authentication). In addition, we are using CanCanCan for authorization of specific tasks. Right now, we just have one role, and that's 'admin.' Later, we might want a more complex permissions structure, but for right now this fits our needs. Any page that requires authentication will redirect the user to the Columbia CAS login page. If a json response is requested, the user is not redirected.

### Statistics
For every asset and item in Academic Commons we store view and download statistics. Assets should only have download statistics and items should only have view statistics. When we calculate download statistics for an item we use the download statistics of its assets. If there are multiple assets associated with an item, we use the download statistics for the most downloaded asset.

### Notifications
- When an item is first added to Academic Commons, we notify the author of the availability of the item if there is a UNI present for the author.

- Monthly statistics email are sent to authors manually. Authors can opt-out of receiving emails by using an unsubscribe link. Administrators can also prevent authors from getting emails by adding an Email Preference for the author.

- Academic Commons staff are sent an email when a new deposit is added or when a new agreement is signed.

- Depositors that self-identify as students are sent a notification that serves as a reminder that departmental approval is required for student works.

### Worker Queue
We are using redis and resque for our worker queue. The worker queue UI can be accessed by administrators are `/admin/resque`. Redis/resque are configured for our deployed production and test environments. Development does not have a worker queue yet.

### Indexing Digital Objects

#### Synchronously (for deployed and local development environments)
To index all items/assets currently in AC, use the following rake task:
```
ac:reindex:all
```

To index specific items and related assets (that are already in AC), use the following rake task:
```
# available parameters: pids
# pids should be a comma-delineated list of pids

ac:reindex:by_item_pid
```

To index specific items/assets, use the following rake task:
```
# available parameters: pids and pidlist
# pids should be a comma-delineated list of pids
# pidlist should be a file with a pid in everyline

ac:reindex_by_pid
```

#### Asynchronously (for deployed test and production environments)
To index all items/assets currently in AC, use the following rake task:
```
rake ac:index:all
```

To index select item/assets, use the following rake task:
```
# available parameters: pids and pidlist
# pids should be a comma-delineated list of pids
# pidlist should be a file with a pid in everyline

rake ac:index:by_pid pids=ac:test1,ac:test2
```
