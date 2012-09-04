require_relative '../test_helper'

describe Peacekeeper::Model do

  describe 'manages an data source selection' do
    # Implementation deatail...
    Peacekeeper::Model.instance_variable_set(:@subclasses, [])

    describe 'set to Active Record' do
      before do
        Peacekeeper::Model.data_source = nil
      end

      it 'requires the Active Record library' do
        -> { Peacekeeper::Model.data_source = :active_record }.should require_lib('active_record')
      end

      it 'loads the Data object for subclasses created before' do
        class BeforeArModel < Peacekeeper::Model;
        end
        Peacekeeper::Model.data_source = :active_record
        lambda do
          BeforeArModel.data_class.should.equal BeforeAr
        end.should require_lib('data/active_record/before_ar')
      end

      it 'loads the Data object for subclasses created after' do
        Peacekeeper::Model.data_source = :active_record
        class AfterArModel < Peacekeeper::Model;
        end
        lambda do
          AfterArModel.data_class.should.equal AfterAr
        end.should require_lib('data/active_record/after_ar')
      end

      it 'propogates the data source setting to subclasses' do
        class BeforeSettingArModel < Peacekeeper::Model;
        end
        Peacekeeper::Model.data_source = :active_record
        class AfterSettingArModel < Peacekeeper::Model;
        end

        BeforeSettingArModel.data_source.should.equal :active_record
        AfterSettingArModel.data_source.should.equal :active_record
      end

      it 'should connect to the Database' do
        Peacekeeper::Model.data_source = :active_record
        ActiveRecord::Base.connection() # Force AR to ~actually~ connect to the DB
        ActiveRecord::Base.connected?.should.equal true
      end
    end
  end
  describe 'used to create a model subclass with Active Record' do
    class MyTestArModel < Peacekeeper::Model
      def test
        :ok
      end
    end

    class MySubtestArModel < Peacekeeper::Model; end

    # Setup the DB and populate with some test data
    Peacekeeper::Model.config['database'] = ':memory:'
    Peacekeeper::Model.config[:protocol] = 'jdbc:sqlite:'
    Peacekeeper::Model.data_source = :active_record

    ActiveRecord::Base.connection.execute("CREATE TABLE my_test_ars (id INTEGER PRIMARY KEY, other_id INTEGER, name STRING);")
    ActiveRecord::Base.connection.execute("CREATE TABLE my_subtest_ars (id INTEGER PRIMARY KEY, my_test_ar_id INTEGER, name STRING);")

    ActiveRecord::Base.connection.execute("INSERT INTO my_test_ars (id,other_id,name) VALUES (1, 2, 'A Test');")
    ActiveRecord::Base.connection.execute("INSERT INTO my_test_ars (id,other_id,name) VALUES (2, 1, 'Other');")
    ActiveRecord::Base.connection.execute("INSERT INTO my_subtest_ars (id,my_test_ar_id,name) VALUES (1, 1, 'First');")
    ActiveRecord::Base.connection.execute("INSERT INTO my_subtest_ars (id,my_test_ar_id,name) VALUES (2, 1, 'Second');")

    it 'delegates data class methods to the data class' do
      (MyTestArModel.respond_to?(:table_name)).should.be.true
      MyTestArModel.table_name.should.equal "my_test_ars"
    end

    describe 'when instantiated' do
      my_test_model = MyTestArModel.new

      it 'creates a data instance' do
        my_test_model.data.class.should.equal MyTestAr
      end

      it 'delegates data methods to the data object' do
        my_test_model.attribute_names.should.equal ['id', 'other_id', 'name']
      end

      it 'still has access to methods defined on the model' do
        my_test_model.test.should.be.equal :ok
      end

      it 'wraps delegated methods that return data class instances' do
        a_test = MyTestArModel.where(name: 'Other').first
        a_test.other.should.be.kind_of MyTestArModel
      end
    end

    it 'wraps a data object return value in a model object' do
      res = MyTestArModel.first
      res.should.be.kind_of MyTestArModel
    end

    it 'wraps a collection of data object return values in model objects' do
      res = MyTestArModel.all
      res.should.be.kind_of Array
      res.each { |i| i.should.be.kind_of MyTestArModel }
    end

    it 'wraps return values from other model objects' do
      test = MyTestArModel.first
      res = test.my_subtest_ars
      res.should.be.kind_of Array
      res.each { |i| i.should.be.kind_of MySubtestArModel }
    end

    it 'maps a hash return value to a hash' do
      res = MyTestArModel.new.attributes
      res.should.be.kind_of Hash
    end

    it 'delegates class methods with an argument' do
      my_test_model = MyTestArModel.create name: 'Another Test'
      my_test_model.should.be.kind_of MyTestArModel
      MyTestArModel.where(name: 'Another Test').first.should.equal my_test_model
    end

    it 'can define methods that operate directly on the data class' do
      class MyTestArModel
        def_data_method :others_first_subtest do
          other.my_subtest_ars.first
        end
      end
      res = MyTestArModel.where(id: 2).first.others_first_subtest
      res.should.be.kind_of MySubtestArModel
      res.name.should.equal 'First'
    end

    it 'can define methods that operate directly on the data class and takes arguments' do
      class MyTestArModel
        def_data_method :others_nth_subtest do |n|
          other.my_subtest_ars[n]
        end
      end
      res = MyTestArModel.where(id: 2).first.others_nth_subtest(1)
      res.should.be.kind_of MySubtestArModel
      res.name.should.equal 'Second'
    end

    it 'can define class methods that operate directly on the data class' do
      class MyTestArModel
        def_singleton_data_method :first_subtest do
          first.my_subtest_ars.first
        end
      end
      res = MyTestArModel.first_subtest
      res.should.be.kind_of MySubtestArModel
      res.name.should.equal 'First'
    end
  end
end

