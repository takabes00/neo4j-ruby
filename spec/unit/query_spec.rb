require 'spec_helper'

describe Neo4j::ActiveNode::Query do
  let(:session) { double('Session') }

  before(:all) do
    @prev_wrapped_classes = Neo4j::ActiveNode::Labels._wrapped_classes
    Neo4j::ActiveNode::Labels._wrapped_classes.clear

    @class_a = Class.new do
      include Neo4j::ActiveNode::Query
      def neo_id
        8724
      end

      def self.name
        'Person'
      end

      def self.neo4j_session
        Neo4j::Session.current
      end
    end
  end

  after(:all) do
    # restore
    Neo4j::ActiveNode::Labels._wrapped_classes.concat(@prev_wrapped_classes)
  end

  describe '.query_as' do
    it 'generates a basic query' do
      @class_a.query_as(:q).to_cypher.should == 'MATCH (q:`Person`)'
    end

    it 'can be built upon' do
      @class_a.query_as(:q).match('q--p').where(p: {name: 'Brian'}).to_cypher.should == 'MATCH (q:`Person`), q--p WHERE (p.name = {p_name})'
    end
  end

  describe '#query_as' do
    it 'generates a basic query' do
      @class_a.new.query_as(:q).to_cypher.should == 'MATCH (q:`Person`) WHERE (ID(q) = {ID_q})'
    end

    it 'can be built upon' do
      @class_a.new.query_as(:q).match('q--p').return(p: :name).to_cypher.should == 'MATCH (q:`Person`), q--p WHERE (ID(q) = {ID_q}) RETURN p.name'
    end
  end
end
