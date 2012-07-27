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
  Peacekeeper::Model.config[:path] = ACTIVERECORD_TEST_DB
  Peacekeeper::Model.config[:driver] = 'com.sqlite3.jdbc.Driver'
  Peacekeeper::Model.config[:database] = 'test_db'

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
    # Repeat config here in case these tests are run alone
    Peacekeeper::Model.config[:path] = ACTIVERECORD_TEST_DB
    Peacekeeper::Model.config[:driver] = 'org.sqlite.JDBC'
    Peacekeeper::Model.config[:database] = 'test_db'
    Peacekeeper::Model.data_source = :active_record

    class MyTestModel < Peacekeeper::Model
      def test
        :ok
      end
    end

    class MySubtestModel < Peacekeeper::Model; end

#    # Setup the DB and populate with some test data
#    DB = ActiveRecord::Model.db
#    DB.drop_table(*DB.tables)
#    DB.create_table :my_tests do
#      primary_key :id
#      foreign_key :other_id, :my_tests
#      String :name
#    end
#    DB[:my_tests].insert(id: 1, other_id: nil, name: 'A Test')
#    DB[:my_tests].insert(id: 2, other_id: 1, name: 'Other')
#    DB[:my_tests].filter(id: 1).update(other_id: 2)
#
#    DB.create_table :my_subtests do
#      primary_key :id
#      foreign_key :my_test_id, :my_tests
#      String :name
#    end
#    DB[:my_subtests].insert(id: 1, my_test_id: 1, name: 'First')
#    DB[:my_subtests].insert(id: 2, my_test_id: 1, name: 'Second')
#    MySubtestModel.new # Instantiate to force loading of data class
#
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
#        a_test = MyTestModel.filter(name: 'Other').first
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
      res = MyTestModel.new.associations
      res.should.be.kind_of Hash
    end

    it 'delegates class methods with an argument' do
      my_test_model = MyTestModel.create name: 'Another Test'
      my_test_model.should.be.kind_of MyTestModel
      MyTestModel.filter(name: 'Another Test').first.should.equal my_test_model
    end

    it 'can define methods that operate directly on the data class' do
      class MyTestModel
        def_data_method :others_first_subtest do
          other.my_subtests.first
        end
      end
      res = MyTestModel.filter(id: 2).first.others_first_subtest
      res.should.be.kind_of MySubtestModel
      res.name.should.equal 'First'
    end

    it 'can define methods that operate directly on the data class and takes arguments' do
      class MyTestModel
        def_data_method :others_nth_subtest do |n|
          other.my_subtests[n]
        end
      end
      res = MyTestModel.filter(id: 2).first.others_nth_subtest(1)
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

