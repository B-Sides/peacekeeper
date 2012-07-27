class MyTest < ActiveRecord::Base
  has_one :other, class_name: "MyTest", foreign_key: :other_id
  has_many :my_subtests
end

