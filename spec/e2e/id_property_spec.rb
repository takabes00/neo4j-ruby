require 'spec_helper'

describe Neo4j::ActiveNode::IdProperty do
  before do
    Neo4j::Config.delete(:id_property)
    Neo4j::Config.delete(:id_property_type)
    Neo4j::Config.delete(:id_property_type_value)
  end


  describe 'abnormal cases' do
    describe 'id_property' do
      it 'raise for id_property :something, :bla' do
        expect do
          UniqueClass.create do
            include Neo4j::ActiveNode
            id_property :something, :bla
          end
        end.to raise_error(/Expected a Hash/)
      end

      it 'raise for id_property :something, bla: 42' do
        expect do
          UniqueClass.create do
            include Neo4j::ActiveNode
            id_property :something, bla: 42
          end
        end.to raise_error(/Illegal value/)
      end
    end
  end


  describe 'when no id_property' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
      end
    end

    it 'uses the neo_id as id after save' do
      SecureRandom.stub(:uuid) { 'secure123' }
      node = clazz.new
      expect(node.id).to eq(nil)
      node.save!
      expect(node.id).to eq('secure123')
    end

    it 'can find by id uses the neo_id' do
      node = clazz.create!
      node.name = 'kalle'
      expect(clazz.find_by_id(node.id)).to eq(node)
    end

    it 'returns :id as primary_key' do
      expect(clazz.primary_key).to eq :uuid
    end

    it 'responds false to id_property' do
      expect(clazz.id_property?).to be_truthy
    end

    describe 'when having a configuration' do
      let(:clazz) do
        UniqueClass.create do
          include Neo4j::ActiveNode
        end
      end

      before do
        Neo4j::Config[:id_property] = :the_id
        Neo4j::Config[:id_property_type] = :auto
        Neo4j::Config[:id_property_type_value] = :uuid
      end

      it 'will set the id_property after a session has been created' do
        node = clazz.new
        expect(node).to respond_to(:the_id)
        expect(clazz.mapped_label.indexes).to eq(property_keys: [[:the_id]])
      end
    end
  end

  describe 'id_property :myid' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        id_property :myid
      end
    end

    it 'has an index' do
      expect(clazz.mapped_label.indexes).to eq(property_keys: [[:myid]])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      clazz.create(myid: 'z')
      clazz.new(myid: 'z')
      expect { clazz.create!(myid: 'z') }.to raise_error(Neo4j::ActiveNode::Persistence::RecordInvalidError)
    end

    describe 'property myid' do
      it 'is not defined when before save ' do
        node = clazz.new
        expect(node.myid).to be_nil
      end

      it 'can be set' do
        node = clazz.new
        node.myid = '42'
        expect(node.myid).to eq('42')
      end

      it 'can be saved after set' do
        node = clazz.new
        node.myid = '42'
        node.save!
        expect(node.myid).to eq('42')
      end

      it 'is same as id' do
        node = clazz.new
        node.myid = '42'
        expect(node.id).to be_nil
      end

      it 'is returned by primary_key' do
        expect(clazz.primary_key).to eq :myid
      end

      it 'makes the class respond true to id_property?' do
        expect(clazz.id_property?).to be_truthy
      end

      it 'removes any previously declared properties' do
        clazz.id_property :my_property, auto: :uuid
        clazz.id_property :another_property, auto: :uuid
        node = clazz.create
        expect(node.respond_to?(:uuid)).to be_falsey
        expect(node.respond_to?(:my_property)).to be_falsey
      end
    end

    describe 'find_by_id' do
      it 'finds it if it exists' do
        clazz.create(myid: 'a')
        node_b = clazz.create(myid: 'b')
        clazz.create(myid: 'c')
        found = clazz.find_by_id('b')
        expect(found).to eq(node_b)
      end

      it 'does not find it if it does not exist' do
        clazz.create(myid: 'd')

        found = clazz.find_by_id('something else')
        expect(found).to be_nil
      end
    end

    describe 'find_by_neo_id' do
      it 'loads by the neo id' do
        node1 = clazz.create
        found = clazz.find_by_neo_id(node1.neo_id)
        expect(found).to eq node1
      end
    end
  end


  describe 'id_property :my_id, on: :foobar' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        id_property :my_id, on: :foobar

        def foobar
          'some id'
        end
      end
    end

    it 'has an index' do
      expect(clazz.mapped_label.indexes).to eq(property_keys: [[:my_id]])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      clazz.default_property :my_id do
        'same uuid'
      end
      clazz.create
      expect { clazz.create }.to raise_error(/Node \d+ already exists with label/)
    end

    describe 'property my_id' do
      it 'is not defined when before save ' do
        node = clazz.new
        expect(node.my_id).to be_nil
      end

      it "is set to foobar's return value after save" do
        node = clazz.new
        node.save
        expect(node.my_id).to eq('some id')
      end

      it 'is same as id' do
        node = clazz.new
        expect(node.id).to be_nil
        node.save
        expect(node.id).to eq(node.my_id)
      end
    end


    describe 'find_by_id' do
      it 'finds it if it exists' do
        clazz.any_instance.stub(:foobar) { 100 }
        node = clazz.create!
        clazz.should_receive(:where).with(my_id: 100).and_return([:some_node])
        expect(clazz.find_by_id(node.my_id)).to eq(:some_node)
      end
    end
  end

  describe 'id_property :my_uuid, auto: :uuid' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        id_property :my_uuid, auto: :uuid
      end
    end

    it 'has an index' do
      expect(clazz.mapped_label.indexes).to eq(property_keys: [[:my_uuid]])
    end

    it 'throws exception if the same uuid is generated when saving node' do
      clazz.default_property :my_uuid do
        'same uuid'
      end
      clazz.create
      expect { clazz.create }.to raise_error(/Node \d+ already exists with label/)
    end

    describe 'property my_uuid' do
      it 'is not defined when before save ' do
        node = clazz.new
        expect(node.my_uuid).to be_nil
      end

      it 'is is set when saving ' do
        node = clazz.new
        node.save
        expect(node.my_uuid).to_not be_empty
      end

      it 'is same as id' do
        node = clazz.new
        expect(node.id).to be_nil
        node.save
        expect(node.id).to eq(node.my_uuid)
      end
    end

    describe 'find_by_id' do
      it 'finds it if it exists' do
        clazz.create
        node = clazz.create
        clazz.create

        found = clazz.find_by_id(node.my_uuid)
        expect(found).to eq(node)
      end

      it 'does not find it if it does not exist' do
        clazz.create

        found = clazz.find_by_id('something else')
        expect(found).to be_nil
      end
    end
  end

  describe 'inheritance' do
    before(:all) do
      module IdProp
        Teacher = UniqueClass.create do
          include Neo4j::ActiveNode
          id_property :my_id, on: :my_method

          def my_method
            'an id'
          end
        end

        class Substitute < Teacher; end

        Vehicle = UniqueClass.create do
          include Neo4j::ActiveNode
          id_property :my_id, auto: :uuid
        end

        class Car < Vehicle; end

        Fruit = UniqueClass.create do
          include Neo4j::ActiveNode

          id_property :my_id
        end

        class Apple < Fruit; end
      end
    end

    after(:all) { [IdProp::Teacher, IdProp::Car, IdProp::Apple].each(&:delete_all) }

    it 'inherits the base id_property' do
      expect(IdProp::Substitute.create.my_id).to eq 'an id'
    end

    it 'works with auto uuid' do
      expect(IdProp::Car.create.my_id).not_to be_nil
    end

    it 'works without conf specified' do
      expect(IdProp::Apple.create.my_id).not_to be_nil
    end

    context 'when a session is not started' do
      it 'waits until the session is loaded, then sets id property' do
        Neo4j::Session.current.close

        module IdProp
          class Executive
            include Neo4j::ActiveNode
            id_property :my_id, on: :my_method

            def my_method
              'an id'
            end
          end

          class CEO < Executive; end
        end

        expect(IdProp::CEO.primary_key).to be_nil
        create_session
        expect(IdProp::CEO.primary_key).not_to be_nil
      end
    end
  end
end
