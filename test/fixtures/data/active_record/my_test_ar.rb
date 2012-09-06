class MyTestAr < ActiveRecord::Base
  has_one :other, class_name: "MyTestAr", foreign_key: :other_id
  has_many :my_subtest_ars
end

