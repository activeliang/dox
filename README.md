[![Build Status](https://travis-ci.org/infinum/dox.svg?branch=master)](https://travis-ci.org/infinum/dox)
[![Code Climate](https://codeclimate.com/github/infinum/dox/badges/gpa.svg)](https://codeclimate.com/github/infinum/dox)
[![Test Coverage](https://codeclimate.com/github/infinum/dox/badges/coverage.svg)](https://codeclimate.com/github/infinum/dox/coverage)

# Dox

Automate your documentation writing process! Dox generates API documentation from Rspec controller/request specs in a Rails application. It formats the tests output in the [OpenApi](https://www.openapis.org/) format. Use the ReDoc renderer for generating and displaying the documentation as HTML.

Here's a [demo app](https://github.com/infinum/dox-demo) and here are some examples:

- [Example not yet added](http://docs.doxdemo.apiary.io/#reference/books/books)


## Installation

Add this line to your application's Gemfile:

```ruby
group :test do
  gem 'dox', require: false
end
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install dox
```

## Usage

### Require it
 Require Dox in the rails_helper:

 ``` ruby
 require 'dox'
 ```

and configure rspec with this:

``` ruby
RSpec.configure do |config|
  config.after(:each, :dox) do |example|
    example.metadata[:request] = request
    example.metadata[:response] = response
  end
end
```

### Configure it
Set these mandatory options in the rails_helper:

| Option | Value | Description |
| -- | -- | -- |
| body_file_path | Pathname instance or fullpath string | Json file that will include openapi version, the basic information about the api, api title and api version. |
| desc_folder_path | Pathname instance or fullpath string | Folder with markdown descriptions. |
| schema_request_folder_path | Pathname instance or fullpath string | Folder with request schemas of resources. |
| schema_response_folder_path | Pathname instance or fullpath string | Folder with response schemas of resources. |

Optional settings:

| Option | Value| Description |
| -- | -- | -- |
| headers_whitelist | Array of headers (strings) | Requests and responses will by default list only `Content-Type` header. To list other http headers, you must whitelist them.|

Example:

``` ruby
Dox.configure do |config|
  config.body_file_path = Rails.root.join('spec/docs/v1/descriptions/header.json')
  config.desc_folder_path = Rails.root.join('spec/docs/v1/descriptions')
  config.schema_request_folder_path = Rails.root.join('spec/docs/v1/schemas')
  config.schema_response_folder_path = Rails.root.join('spec/support/v1/schemas')
  config.headers_whitelist = ['Accept', 'X-Auth-Token']
end
```

### Basic example

Define a descriptor module for a resource using Dox DSL:

``` ruby
module Docs
  module V1
    module Bids
      extend Dox::DSL::Syntax

      # define common resource data for each action
      document :api do
        resource 'Bids' do
          endpoint '/bids'
          group 'Bids'
          desc 'bids.md'
        end
      end

      # define data for specific action
      document :index do
        action 'Get bids'
      end
    end
  end
end

```
<small>You can define the descriptors for example in specs/docs folder, just make sure you load them in the rails_helper.rb:

``` ruby
Dir[Rails.root.join('spec/docs/**/*.rb')].each { |f| require f }
```
</small>

Include the descriptor modules in a controller and tag the specs you want to document with **dox**:

``` ruby
describe Api::V1::BidsController, type: :controller do
  # include resource module
  include Docs::V1::Bids::Api

  describe 'GET #index' do
    # include action module
    include Docs::V1::Bids::Index

    it 'returns a list of bids', :dox do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end
end
```

And [generate the documentation](#generate-documentation).


### Advanced options

Before running into any more details, here's roughly how the generated OpenApi document is structured:

- openapi
- info
- paths
  - action 1
    - tag1
    - example 1
    - example 2
  - action 2
    - tag2
    - example 3
- x-tagGroups
      - tags1
        - tag 1
        - tag 2
      - tags2
        - tag 3
        - tag 4
- tags
  - tag1
  - tag2


OpenApi and info are defined in a json file as mentioned before. Examples are concrete test examples (you can have multiple examples for both happy and fail paths). They are completely automatically generated from the request/response objects.
And you can customize the following in the descriptors:

- x-tagGroup (**resourceGroup**)
- tag (**resource**)
- action
- example

#### ResourceGroup

ResourceGroup contains related resources and is defined with:
- **name** (required)
- desc (optional, inline string or relative filepath)

Example:
``` ruby
document :bids_group do
  group 'Bids' do
    desc 'Here are all bid related resources'
  end
end
```

You can omit defining the resource group, if you don't have any description for it. Related resources will be linked in a group by the group option at the resource definition.

#### Resource
Resource contains actions and is defined with:
- **name** (required)
- **endpoint** (required)
- **group** (required; to associate it with the related group)
- desc (optional; inline string or relative filepath)

Example:
``` ruby
document :bids do
  resource 'Bids' do
    endpoint '/bids'
    group 'Bids'
    desc 'bids/bids.md'
  end
end
```

Usually you'll want to define resourceGroup and resource together, so you don't have to include 2 modules with common data per spec file:

``` ruby
document :bids_common do
  group 'Bids' do
    desc 'Here are all bid related resources'
  end

  resource 'Bids' do
    endpoint '/bids'
    group 'Bids'
    desc 'bids/bids.md'
  end
end
```

#### Action
Action contains examples and is defined with:
- **name** (required)
- **resource** (required, parent resource)
- path* (optional)
- verb* (optional)
- params* (optional)
- desc (optional; inline string or relative filepath)
- request_schema (optional; inline string or relative filepath)
- response_schema_success (optional; inline string or relative filepath)
- response_schema_fail (optional; inline string or relative filepath)

\* these optional attributes are guessed (if not defined) from the request object of the test example and you can override them.

Example:

``` ruby
show_params = { id: { type: :number, required: :required, value: 1, description: 'bid id' } }

document :action do
  action 'Get bid' do
    path '/bids/{id}'
    verb 'GET'
    params show_params
    desc 'Some description for get bid action'
    request_schema 'namespace/bids'
    response_schema_success 'namespace/bids_s'
    response_schema_fail 'namespace/bids_f'
  end
end
```

### Generate documentation
Documentation is generated in 2 steps:

1. generate OpenApi json file:
```bundle exec rspec --tag apidoc -f Dox::Formatter --order defined --tag dox --out spec/api_doc/v1/schemas/docs.json```

2. render HTML with Redoc:
```redoc-cli bundle -o public/api/docs/v2/docs.html spec/api_doc/v1/schemas/docs.json```


#### Use rake tasks
It's recommendable to write a few rake tasks to make things easier. Here's an example:

```ruby
namespace :api do
  namespace :doc do
    desc 'Generate API documentation markdown'
    task :json do
      require 'rspec/core/rake_task'

      RSpec::Core::RakeTask.new(:api_spec) do |t|
        t.pattern = 'spec/controllers/api/v1/'
        t.rspec_opts = "-f Dox::Formatter --order defined --tag dox --out public/api/docs/v1/docs.json"
      end

      Rake::Task['api_spec'].invoke
    end

    task html: :json do
      `redoc-cli bundle -o public/api/docs/v2/index.html spec/api_doc/v1/schemas/docs.json`
    end

    task open: :html do
      `open public/api/docs/v1/index.html`
    end
  end
end
```

#### Renderers
You can render the HTML yourself with ReDoc:

- [Redoc](https://github.com/Redocly/redoc)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/infinum/dox. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## Credits
Dox is maintained and sponsored by [Infinum](https://infinum.co).

<a href="https://infinum.co"><img alt="Infinum" src="infinum.png" width="250"></a>

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
