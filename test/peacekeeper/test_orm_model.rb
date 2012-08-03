require_relative '../test_helper'
require 'peacekeeper/model'

###
#
# This is a dirty, dirty trick to write tests that test `require`:
#
module RequireMock
  REQUIRE_SENTINEL = []

  def require(lib)
    REQUIRE_SENTINEL << lib
    super
  end
end
Object.send(:include, RequireMock)

def require_lib(lib)
  ->(block) do
    REQUIRE_SENTINEL.clear
    block.call
    REQUIRE_SENTINEL.include?(lib)
  end
end

#
###

describe Peacekeeper::Model do

  describe 'manages an data source selection' do
    # Implementation deatail...
    Peacekeeper::Model.instance_variable_set(:@subclasses, [])

    it 'is nil by default' do
      Peacekeeper::Model.data_source.should.be.nil
    end

    describe 'set to Active Record' do
      before do
        Peacekeeper::Model.data_source = nil
      end

      it 'requires the Active Record library' do
        -> { Peacekeeper::Model.data_source = :active_record }.should require_lib('active_record')
      end

      it 'loads the Data object for subclasses created before' do
        class BeforeModel < Peacekeeper::Model;
        end
        Peacekeeper::Model.data_source = :active_record
        lambda do
          BeforeModel.data_class.should.equal Before
        end.should require_lib('data/active_record/before')
      end

      it 'loads the Data object for subclasses created after' do
        Peacekeeper::Model.data_source = :active_record
        class AfterModel < Peacekeeper::Model;
        end
        lambda do
          AfterModel.data_class.should.equal After
        end.should require_lib('data/active_record/after')
      end

      it 'propogates the data source setting to subclasses' do
        class BeforeSettingModel < Peacekeeper::Model;
        end
        Peacekeeper::Model.data_source = :active_record
        class AfterSettingModel < Peacekeeper::Model;
        end

        BeforeSettingModel.data_source.should.equal :active_record
        AfterSettingModel.data_source.should.equal :active_record
      end

      #it 'should only connect to the Database once' do
      #  class BeforeModel < Peacekeeper::Model;
      #  end
      #  class BeforeSettingModel < Peacekeeper::Model;
      #  end
      #  Peacekeeper::Model.data_source = :active_record
      #  class AfterModel < Peacekeeper::Model;
      #  end
      #  class AfterSettingModel < Peacekeeper::Model;
      #  end
      #  ActiveRecord::DATABASES.length.should.equal 1
      #end
    end
  end
  describe 'used to create a model subclass with Active Record' do
    class MyTestModel < Peacekeeper::Model
      def test
        :ok
      end
    end

    class MySubtestModel < Peacekeeper::Model; end

    # Setup the DB and populate with some test data
    Peacekeeper::Model.config['database'] = ACTIVERECORD_TEST_DB
    Peacekeeper::Model.config['adapter'] = 'sqlite3'
    Peacekeeper::Model.data_source = :active_record

    ActiveRecord::Base.connection.execute("DROP TABLE my_tests;")
    ActiveRecord::Base.connection.execute("DROP TABLE my_subtests;")
    ActiveRecord::Base.connection.execute("CREATE TABLE my_tests (id INTEGER PRIMARY KEY, other_id INTEGER, name STRING);")
    ActiveRecord::Base.connection.execute("CREATE TABLE my_subtests (id INTEGER PRIMARY KEY, my_test_id INTEGER, name STRING);")

    ActiveRecord::Base.connection.execute("INSERT INTO my_tests (id,other_id,name) VALUES (1, 2, 'A Test');")
    ActiveRecord::Base.connection.execute("INSERT INTO my_tests (id,other_id,name) VALUES (2, 1, 'Other');")
    ActiveRecord::Base.connection.execute("INSERT INTO my_subtests (id,my_test_id,name) VALUES (1, 1, 'First');")
    ActiveRecord::Base.connection.execute("INSERT INTO my_subtests (id,my_test_id,name) VALUES (2, 1, 'Second');")

#    it 'delegates data class methods to the data class' do
#      (MyTestModel.respond_to?(:table_name)).should.be.true
#      MyTestModel.table_name.should.equal :my_tests
#    end
#
#    describe 'when instantiated' do
#      my_test_model = MyTestModel.new
#
#      it 'creates a data instance' do
#        my_test_model.data.class.should.equal MyTest
#      end
#
#      it 'delegates data methods to the data object' do
#        my_test_model.columns.should.equal [:id, :other_id, :name]
#      end
#
#      it 'still has access to methods defined on the model' do
#        my_test_model.test.should.be.equal :ok
#      end
#
#      it 'wraps delegated methods that return data class instances' do
#        a_test = MyTestModel.where(name: 'Other').first
#        a_test.other.should.be.kind_of MyTestModel
#      end
#    end

    it 'wraps a data object return value in a model object' do
      res = MyTestModel.first
      res.should.be.kind_of MyTestModel
    end

    it 'wraps a collection of data object return values in model objects' do
      res = MyTestModel.all
      res.should.be.kind_of Array
      res.each { |i| i.should.be.kind_of MyTestModel }
    end

    it 'wraps return values from other model objects' do
      test = MyTestModel.first
      res = test.my_subtests
      res.should.be.kind_of Array
      res.each { |i| i.should.be.kind_of MySubtestModel }
    end

    it 'maps a hash return value to a hash' do
      res = MyTestModel.new.attributes
      res.should.be.kind_of Hash
    end

    it 'delegates class methods with an argument' do
      my_test_model = MyTestModel.create name: 'Another Test'
      my_test_model.should.be.kind_of MyTestModel
      MyTestModel.where(name: 'Another Test').first.should.equal my_test_model
    end

    it 'can define methods that operate directly on the data class' do
      class MyTestModel
        def_data_method :others_first_subtest do
          other.my_subtests.first
        end
      end
      res = MyTestModel.where(id: 2).first.others_first_subtest
      res.should.be.kind_of MySubtestModel
      res.name.should.equal 'First'
    end

    it 'can define methods that operate directly on the data class and takes arguments' do
      class MyTestModel
        def_data_method :others_nth_subtest do |n|
          other.my_subtests[n]
        end
      end
      res = MyTestModel.where(id: 2).first.others_nth_subtest(1)
      res.should.be.kind_of MySubtestModel
      res.name.should.equal 'Second'
    end

    it 'can define class methods that operate directly on the data class' do
      class MyTestModel
        def_singleton_data_method :first_subtest do
          first.my_subtests.first
        end
      end
      res = MyTestModel.first_subtest
      res.should.be.kind_of MySubtestModel
      res.name.should.equal 'First'
    end
  end
end

