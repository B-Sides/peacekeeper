class MyTest < Sequel::Model
  one_to_many :my_sub_tests
end

class MySubTest < Sequel::Model
  many_to_one :my_test
end
