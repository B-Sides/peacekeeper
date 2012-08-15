## What is Peacekeeper?

Peacekeeper is a simple delegation library that allows the creation of business objects (Peacekeeper models) that hide the data objects they pull from. This allows a clean separation of business logic and data logic, without any kind of imposition on how the data is stored. Business objects (Peacekeeper models) can pull from an API resource or database resource, or this can be changed at runtime.

Peacekeeper delegates any unknown methods from your business objects directly to their respective data object.

examples usages for each DB type:

```ruby
# API resource using Nasreddin
# lib/models/car_model.rb
class CarModel < Peacekeeper::Model
  self.data_source = :api
  # application specific business logic
end

# lib/data/api/car.rb
class Car < Nasreddin::Resource('cars')
  # data retrieval logic
end

# Database resource using Sequel
# lib/models/car_model.rb
class CarModel < Peacekeeper::Model
  self.data_source = :sequel # Can also use :active_record
  # application specific business logic
end

# lib/data/sequel/car.rb
class Car < Sequel::Model
  # data retrieval logic
end

# lib/data/active_record/car.rb
class Car < ActiveRecord::Base
  # data retrieval logic
end
```

# Setting up Peacekeeper
Peacekeeper requires that your data source be configured. This can be done in a
yaml file:

```yaml
default: &default
  adapter: <%= defined?(JRUBY_VERSION) ? 'jdbc:mysql':'mysql2' %> 
  username: root
  password:
  host: localhost
  xa: false

development:
  <<: *default
  database: dev
test:
  <<: *default
  database: test
build:
  <<: *default
  database: build
staging:
  <<: *default
  database: staging
production:
  <<: *default
  database: production
```

# Sinatra
If you are using Sinatra, you can setup Peacekeeper with something like this in
your lib dir.

```ruby
# lib/database.rb
dbcfg = File.read(File.expand_path('config/database.yml', APP_ROOT))
dbcfg = ERB.new(dbcfg).result(binding)
Peacekeeper::Model.config = YAML.load(dbcfg)[ENV['RACK_ENV']]
Sequel.default_timezone = :utc
```

# Rails
If you are using Rails, you can setup Peacekeeper with something like this in
your application.rb.

```ruby
# config/application.rb
class Application < Rails::Application
  dbcfg = File.read(File.expand_path('config/database.yml', config.root))
  dbcfg = ERB.new(dbcfg).result(binding)
  Peacekeeper::Model.config = YAML.load(dbcfg)[Rails.env]
end
```

# Testing with Peacekeeper
Peacekeeper also makes testing easy with the :mock ORM type, this can be set in your test code which sets Peacekeeper to return mock objects from any delegated methods.
You will need a mocking library installed that responds to mock(). If you are using rspec, add this to your spec_helper.rb file:

```ruby
RSpec.configure do |config|
  config.before(:all) do
    Peacekeeper::Model.config[:mock_library] = 'mocha'
    Peacekeeper::Model.data_source = :mock
  end
end
```

example usage:
```ruby
describe 'CarModel' do
  CarModel.data_source = :mock
  # test business logic
end
```

