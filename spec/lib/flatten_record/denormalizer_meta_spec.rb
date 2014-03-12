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


describe FlattenRecord::DenormalizerMeta do
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

  context "when nested denormalize() is defined " do
    it 'should have the target+nested_target model columns ' do
      klass.class_eval do
        denormalize :target do |target|
          target.denormalize :nested_target
        end
      end
      meta = klass.denormalizer_meta
  
      target_col_count = Target.columns.count  
      nested_target_col_count = NestedTarget.columns.count 
      expect(meta.denormalized_columns.count).to eq(target_col_count+nested_target_col_count)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('d_nested_target_nested_target_id')
      expect(columns).to include('d_nested_target_total')
    end
  end

  context "when nested(x2) denormalize() is defined " do
    it 'should have the target+nested_target+child model columns ' do
      klass.class_eval do
        denormalize :target do |target|
          target.denormalize :nested_target do |nested_target|
            nested_target.denormalize :child
          end
        end
      end
      meta = klass.denormalizer_meta
  
      target_col_count = Target.columns.count  
      nested_target_col_count = NestedTarget.columns.count
      child_col_count = Child.columns.count
      expect(meta.denormalized_columns.count).
        to eq(target_col_count+nested_target_col_count+child_col_count)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('d_nested_target_child_child_id')
      expect(columns).to include('d_nested_target_child_total')
    end
  end

  context "when save() is defined " do
    it 'should have the custom columns ' do
      klass.class_eval do
        denormalize :target do |target|
          target.save :custom, :integer
          target.denormalize :nested_target do |nested_target|
            nested_target.save :custom, :integer
            nested_target.denormalize :child
          end
        end
      end
      meta = klass.denormalizer_meta
  
      target_col_count = Target.columns.count  
      nested_target_col_count = NestedTarget.columns.count
      child_col_count = Child.columns.count
      expect(meta.denormalized_columns.count).
        to eq(target_col_count+nested_target_col_count+child_col_count+2)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('custom')
      expect(columns).to include('d_nested_target_custom')
    end
  end

end

