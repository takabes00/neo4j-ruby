require 'spec_helper'

describe Neo4j::ActiveNode do
  class SimpleClass
    include Neo4j::ActiveNode
    property :name
  end

  describe SimpleClass do
    context 'when instantiated with new()' do
      subject do
        SimpleClass.new
      end

      it 'does not have any attributes' do
        subject.attributes.should eq('name' => nil)
      end

      it 'returns nil when asking for a attribute' do
        subject['name'].should be_nil
      end

      it 'can set attributes' do
        subject['name'] = 'foo'
        subject['name'].should eq('foo')
      end

      it 'allows symbols instead of strings in [] and []= operator' do
        subject[:name] = 'foo'
        subject['name'].should eq('foo')
        subject[:name].should eq('foo')
      end

      it 'allows setting attributes to nil' do
        subject['name'] = nil
        subject['name'].should be_nil
        subject['name'] = 'foo'
        subject['name'] = nil
        subject['name'].should be_nil
      end
    end

    context 'when instantiated with new(name: "foo")' do
      subject { SimpleClass.new(unknown: 'foo') }

      it 'does not allow setting undeclared properties' do
        expect { subject }.to raise_error Neo4j::Shared::Property::UndefinedPropertyError
      end
    end
  end
end
