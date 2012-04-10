class MyTest < Sequel::Model
  one_to_one :other, class: MyTest, key: :other_id
  one_to_many :my_subtests
end

