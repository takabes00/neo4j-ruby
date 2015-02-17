require 'spec_helper'

describe 'wrapped nodes in transactions' do
  module TransactionNode
    class Teacher; end
    class StudentTeacher; end

    class Student
      include Neo4j::ActiveNode
      property :name

      has_many :out, :teachers, model_class: Teacher, rel_class: StudentTeacher
    end

    class Teacher
      include Neo4j::ActiveNode
      property :name
      has_many :in, :students, model_class: Student, rel_class: StudentTeacher
    end

    class StudentTeacher
      include Neo4j::ActiveRel
      from_class TransactionNode::Student
      to_class TransactionNode::Teacher
      type 'teacher'
      property :appreciation, type: Integer
    end
  end

  before(:all) do
    @student = TransactionNode::Student
    @teacher = TransactionNode::Teacher
    @student.delete_all
    @teacher.delete_all

    @student.create(name: 'John')
    @teacher.create(name: 'Mr Jones')
    begin
      tx = Neo4j::Transaction.new
      @john = @student.first
      @jones = @teacher.first
    ensure
      tx.close
    end
  end

  it 'can load a node within a transaction' do
    expect(@john).to be_a(@student)
    expect(@john.name).to eq 'John'
    expect(@john.id).not_to be_nil
  end

  it 'returns its :labels' do
    expect(@john.neo_id).not_to be_nil
    expect(@john.labels).to eq [@student.name.to_sym]
  end

  it 'responds positively to exist?' do
    expect(@john.exist?).to be_truthy
  end

  describe 'relationships' do
    let!(:rel) { TransactionNode::StudentTeacher.create(from_node: @john, to_node: @jones, appreciation: 9000) }

    it 'allows the creation of rels using transaction-loaded nodes' do
      expect(rel.persisted?).to be_truthy
      expect(rel.appreciation).to eq 9000
    end

    it 'will load rels within a tranaction' do
      begin
        tx = Neo4j::Transaction.new
        retrieved_rel = @john.teachers.each_rel do |r|
          expect(r).to be_a(TransactionNode::StudentTeacher)
        end
      ensure
        tx.close
      end
      expect(retrieved_rel.first).to be_a(TransactionNode::StudentTeacher)
    end

    it 'does not create an additional relationship after load then save' do
      starting_count = @john.teachers_rels.count
      begin
        tx = Neo4j::Transaction.new
        @john.teachers.each_rel do |r|
          r.appreciation = 9001
          r.save
        end
      ensure
        tx.close
      end
      @john.reload
      expect(@john.teachers_rels.count).to eq starting_count
    end
  end
end
