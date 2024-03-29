require_relative '../test_helper'

describe Peacekeeper::Model do
  it 'cannot be instantiated directly' do
    -> { Peacekeeper::Model.new }.should.raise(RuntimeError)
  end

  class SubclassTestModel < Peacekeeper::Model; end

  it 'derives a model name based on the subclass\'s name' do
    SubclassTestModel.data_name.should.equal 'SubclassTest'
  end

  it 'derives a data library name based on the subclass\'s name' do
    SubclassTestModel.data_lib_name.should.equal 'subclass_test'
  end

  describe 'manages a database config' do
    #it 'is empty by default' do
    #  Peacekeeper::Model.config.should.be.empty
    #end

    it 'is inherited by subclasses' do
      path = 'tmp/test_db.sqlite'
      class SubclassBeforeModel < Peacekeeper::Model;
      end
      Peacekeeper::Model.config = {path: path}
      class SubclassAfterModel < Peacekeeper::Model;
      end

      SubclassBeforeModel.config[:path].should.equal path
      SubclassAfterModel.config[:path].should.equal path
    end
  end

  describe 'used to create a model subclass with Sequel' do
    # Repeat config here in case these tests are run alone
    Peacekeeper::Model.config[:protocol] = 'jdbc:sqlite::memory:'
    Peacekeeper::Model.data_source = :sequel

    class MyTestModel < Peacekeeper::Model
      def test
        :ok
      end
    end

    class MySubtestModel < Peacekeeper::Model; end

    # Setup the DB and populate with some test data
    DB = Sequel::Model.db
    DB.create_table :my_tests do
      primary_key :id
      foreign_key :other_id, :my_tests
      String :name
    end
    DB[:my_tests].insert(id: 1, name: 'A Test')
    DB[:my_tests].insert(id: 2, other_id: 1, name: 'Other')
    DB[:my_tests].filter(id: 1).update(other_id: 2)

    DB.create_table :my_subtests do
      primary_key :id
      foreign_key :my_test_id, :my_tests
      String :name
    end
    DB[:my_subtests].insert(id: 1, my_test_id: 1, name: 'First')
    DB[:my_subtests].insert(id: 2, my_test_id: 1, name: 'Second')
    MySubtestModel.new # Instantiate to force loading of data class

    it 'delegates data class methods to the data class' do
      (MyTestModel.respond_to?(:table_name)).should.be.true
      MyTestModel.table_name.should.equal :my_tests
    end

    describe 'when instantiated' do
      my_test_model = MyTestModel.new

      it 'creates a data instance' do
        my_test_model.data.class.should.equal MyTest
      end

      it 'delegates data methods to the data object' do
        my_test_model.columns.should.equal [:id, :other_id, :name]
      end

      it 'still has access to methods defined on the model' do
        my_test_model.test.should.be.equal :ok
      end

      it 'wraps delegated methods that return data class instances' do
        a_test = MyTestModel.filter(name: 'Other').first
        a_test.other.should.be.kind_of MyTestModel
      end
    end

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
    it 'should prevent calling :to_json inherited from Object' do
      class Object
        def to_json
          raise "don't call me"
        end
      end
      class MyTestModel < Peacekeeper::Model
      end
      class MyTest
        def to_json
          :ok
        end
      end
      MyTestModel.new.to_json.should.equal :ok
      -> { Object.new.to_json }.should.raise(RuntimeError)
    end

    it 'should allow redefinition of :to_json in the model' do
      class Object
        def to_json
          raise "don't call me"
        end
      end
      class MyTestModel < Peacekeeper::Model
        def to_json
          :ok
        end
      end
      class MyTest
        def to_json
          :ko
        end
      end
      MyTestModel.new.to_json.should.equal :ok
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

  # These are too close to testing the implementation with the implementation.
  # We should probably either test URL construction indirectly or using mocks.
  # TODO: Implement a test for config['options'] as well.
  #describe 'database connection uri' do
  #  username = Peacekeeper::Model.config['username'] = 'username'
  #  password = Peacekeeper::Model.config['password'] = 'password'
  #  host = Peacekeeper::Model.config['host'] = 'localhost'
  #  database = Peacekeeper::Model.config['database'] = 'database'

  #  describe "when specified adapter is 'jdbc:mysql'" do
  #    it 'generate uri for jdbc:mysql' do
  #      adapter = Peacekeeper::Model.config['adapter'] = 'jdbc:mysql'
  #      Peacekeeper::Model.sequel_db_uri.should.eql "#{adapter}://#{host}/#{database}?user=#{username}&password=#{password}"
  #    end
  #  end

  #  describe "when specified adapter is not 'jdbc:mysql'" do
  #    it 'generate non-jdbc uri' do
  #      adapter = Peacekeeper::Model.config['adapter'] = 'mysql2'
  #      Peacekeeper::Model.sequel_db_uri.should.eql "#{adapter}://#{username}:#{password}@#{host}/#{database}"
  #    end
  #  end

  #  describe "when no adapter is specified" do
  #    it 'generate sqlite uri' do
  #      Peacekeeper::Model.config = {}
  #      Peacekeeper::Model.sequel_db_uri.should.eql 'sqlite:/'
  #    end
  #  end
  #end
end

