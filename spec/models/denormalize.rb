class FlattenRecord::Denormalize::Test 
  def self.setup_models
    ActiveRecord::Schema.define do 
      ActiveRecord::Base.connection.tables.each do |old_table|
        drop_table old_table
      end
      
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
    ActiveRecord::Base.connection.schema_cache.clear!
   
    %w{Child NestedTarget Target}.each do |klass_name|
      klass = Class.new(ActiveRecord::Base)
      Object.send(:remove_const, klass_name.to_sym) if Object.const_defined?(klass_name.to_sym)
      Object.const_set(klass_name, klass)
    end
  
    NestedTarget.class_eval do
      belongs_to :child
    end
    
    Target.class_eval do
      belongs_to :nested_target
    end
    
    [Target, NestedTarget, Child].each do |klass|
      klass.reset_column_information
    end
  end
  
  def self.delete_models
    [Target, NestedTarget, Child].each do |klass|
      Object.send(:remove_const, klass.to_s.to_sym)
    end
  
    ActiveRecord::Schema.define(version: 'denormalize') do 
      ActiveRecord::Base.connection.tables.each do |old_table|
        drop_table old_table
      end
    end 
  end
end
