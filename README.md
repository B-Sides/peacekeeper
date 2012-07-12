## What is Peacekeeper?

Peacekeeper is a simple delegation library that allows the creation of business objects (Peacekeeper models) that hide the data objects they pull from. This allows a clean separation of business logic and data logic, without any kind of imposition on how the data is stored. Business objects (Peacekeeper models) can pull from an API resource or database resource, or this can be changed at runtime.

Peacekeeper delegates any unknown methods from your business objects directly to their respective data object.

examples usages for each DB type:

```ruby
# API resource using Nasreddin
# lib/models/car_model.rb
class CarModel < Peacekeeper::Model
  self.orm = :api
  # application specific business logic
end
# lib/data/api/car.rb
class Car < Nasreddin::Resource('cars')
  # data retrieval logic
end

# Database resource using Sequel
# lib/models/car_model.rb
class CarModel < Peacekeeper::Model
  self.orm = :sequel
  # application specific business logic
end
# lib/data/sequel/car.rb
class Car < Sequel::Model
  # data retrieval logic
end
```

Peacekeeper also makes testing easy with the :mock ORM type, this can be set in your test code which sets Peacekeeper to return mock objects from any delegated methods.

example usage:
```ruby
describe 'CarModel' do
  CarModel.orm_type = :mock
  # test business logic
end
```
