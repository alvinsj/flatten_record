require 'spec_helper'

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :targets do |t|
      t.integer :total
      t.integer :nested_target_id
    end
    create_table :nested_targets do |t|
      t.integer :total
      t.integer :child_id
    end
    create_table :children do |t|
      t.column :total, :integer
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end


describe FlattenRecord::Denormalize do
  before do
    setup_db 
    class Child < ActiveRecord::Base; end
    class NestedTarget < ActiveRecord::Base; belongs_to :child; end 
    class Target < ActiveRecord::Base; belongs_to :nested_target;end
  end 
  after do 
    teardown_db
  end

  let(:klass) do
    class Denormalized < ActiveRecord::Base
      include FlattenRecord::Denormalize
    end
  end
 
  context 'when it is included' do  
    it 'should exists in Meta' do      
      expect(klass::Meta).to_not be_nil
      expect(klass::Meta.included_classes).to_not be_nil
      expect(klass::Meta.included_classes).to include(Denormalized.name)
    end
  end

  context "when denormalize() is defined " do
    it 'should save the meta and add denormalize methods' do
      klass.class_eval do
        denormalize :target do |target|
        end
      end
      expect(klass.denormalizer_meta).to_not be_nil
      expect(klass.parent_model.name).to eql(Target.name)
      expect(klass).to respond_to(:create_denormalized)
      expect(klass).to respond_to(:destroy_denormalized)
    end

  end

end

