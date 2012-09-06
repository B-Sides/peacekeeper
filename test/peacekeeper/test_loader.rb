require_relative '../test_helper'

describe Peacekeeper::Loader do
  describe 'manages a data source selection' do
    # Implementation deatail...
    Peacekeeper::Model.instance_variable_set(:@subclasses, [])

    it 'is nil by default' do
      Peacekeeper::Model.data_source.should.be.nil
    end

    describe 'set to Sequel' do
      before do
        Peacekeeper::Model.data_source = nil
      end

      it 'requires the Sequel library' do
        loader = mock("Loader")
        loader.should.receive(:load_source)
        Peacekeeper::Loader.should.receive(:new).and_return(loader)
        Peacekeeper::Model.data_source = :sequel
      end

      it 'loads the Data object for subclasses created before' do
        loader = mock("Loader")
        loader.should.receive(:load_source).times(3)
        Peacekeeper::Loader.should.receive(:new).times(3).and_return(loader)

        class BeforeModel < Peacekeeper::Model;
        end
        Peacekeeper::Model.data_source = :sequel
        lambda do
          BeforeModel.data_class.should.equal Before
        end
      end

      it 'loads the Data object for subclasses created after' do
        loader = mock("Loader")
        loader.should.receive(:load_source).times(3)
        Peacekeeper::Loader.should.receive(:new).times(3).and_return(loader)

        Peacekeeper::Model.data_source = :sequel
        class AfterModel < Peacekeeper::Model;
        end
        lambda do
          AfterModel.data_class.should.equal After
        end
      end

      it 'propogates the ORM setting to subclasses' do
        class BeforeSettingModel < Peacekeeper::Model;
        end
        Peacekeeper::Model.data_source = :sequel
        class AfterSettingModel < Peacekeeper::Model;
        end

        BeforeSettingModel.data_source.should.equal :sequel
        AfterSettingModel.data_source.should.equal :sequel
      end

      it 'should only connect to the Database once' do
        class BeforeModel < Peacekeeper::Model;
        end
        class BeforeSettingModel < Peacekeeper::Model;
        end
        Peacekeeper::Model.data_source = :sequel
        class AfterModel < Peacekeeper::Model;
        end
        class AfterSettingModel < Peacekeeper::Model;
        end
        Sequel::DATABASES.length.should.equal 1
      end
    end

    describe 'set to Active Record' do
      before do
        Peacekeeper::Model.data_source = nil
      end

      it 'requires the Active Record library' do
        loader = mock("Loader")
        loader.should.receive(:load_source).times(5)
        Peacekeeper::Loader.should.receive(:new).times(5).and_return(loader)
        Peacekeeper::Model.data_source = :active_record
      end

      it 'should connect to the Database' do
        Peacekeeper::Model.data_source = :active_record
        ActiveRecord::Base.connection() # Force AR to ~actually~ connect to the DB
        ActiveRecord::Base.connected?.should.equal true
      end
    end

    describe 'set to mock' do
      Peacekeeper::Model.data_source = :nil
      Peacekeeper::Model.config[:mock_library] = 'facon'

      it 'requires the facon library' do
        loader = mock("Loader")
        loader.should.receive(:load_source).times(5)
        Peacekeeper::Loader.should.receive(:new).times(5).and_return(loader)

        Peacekeeper::Model.data_source = :mock
      end

      it 'creates a data class ready for mocking' do
        class MyMockModel < Peacekeeper::Model; end
        defined?(MyMock).should.equal 'constant'
        MyMock.should.receive(:delegate_call)
        MyMockModel.delegate_call
      end

      it 'returns empty mocks for data class calls by default' do
        class MyMockableModel < Peacekeeper::Model; end

        foo = MyMockableModel.get_foo

        foo.name.should.equal 'MyMockable'
        foo.should.be.kind_of Facon::Mock
      end

      it 'returns a mock with properties set when #new is called with options' do
        class MyInstantiableMockModel < Peacekeeper::Model; end

        user = MyInstantiableMockModel.new(name: "Joe", position: :employee, vacation_days: 14)

        user.name.should.equal "Joe"
        user.position.should.equal :employee
        user.vacation_days.should.equal 14
      end

      # Implementation deatail...
      Peacekeeper::Model.instance_variable_set(:@subclasses, [])
    end
  end

end
