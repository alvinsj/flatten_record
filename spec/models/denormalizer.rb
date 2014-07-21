class FlattenRecord::Denormalizer::Test
  def self.setup_models
    ActiveRecord::Schema.define do
      ActiveRecord::Base.connection.tables.each do |old_table|
        drop_table old_table
      end
     
      create_table :orders do |t|
        t.integer :total
        t.integer :customer_id
      end
      create_table :customers do |t|
        t.string :name
      end
      create_table :children do |t|
        t.string :name
        t.integer :customer_id
      end
      create_table :cats do |t|
        t.string :name
        t.string :owner_type
        t.integer :owner_id
      end
      create_table :denormalizeds do |t|
        t.integer :order_id
        t.integer :total
        t.integer :customer_id
        t.integer :d_customer_customer_id
        t.string :d_customer_name
        t.integer :d_customer_number_of_children
        t.integer :d_customer_children_child_id
        t.integer :d_customer_children_customer_id
        t.string :d_customer_children_name
        t.integer :d_customer_parent_id
        t.string :d_customer_cats_cat_id
        t.string :d_customer_cats_name
        t.string :d_customer_cats_owner_type
        t.integer :d_customer_cats_owner_id
      end
    end
    ActiveRecord::Base.connection.schema_cache.clear!
    
    %w{Cat Child Customer Order Denormalized}.each do |klass_name|
      klass = Class.new(ActiveRecord::Base)
      Object.send(:remove_const, klass_name.to_sym) if Object.const_defined?(klass_name.to_sym)
      Object.const_set(klass_name, klass)
    end
  
    Cat.class_eval do
      belongs_to :owner, polymorphic: true 
    end
    
    Child.class_eval do
      belongs_to :customer
      has_many :cats, as: :owner
    end
    
    Customer.class_eval do
      has_many :children, class_name: Child
      has_many :cats, as: :owner; 
    end 
    
    Order.class_eval do
      belongs_to :customer
    end
     
    Denormalized.class_eval do
      include FlattenRecord::Denormalize
      denormalize :order do |order|
        order.denormalize :customer do |customer|
          customer.denormalize :children
          customer.denormalize :cats, as: :cat, parent_as: :owner
          customer.save :number_of_children, :integer
        end
      end
      def _get_number_of_children(customer)
        customer.children ? customer.children.count : 0
      end
    end
    
    [Cat, Child, Customer, Order, Denormalized].each do |klass|
      klass.reset_column_information
    end
  end
  
  def self.delete_models
    [Cat, Child, Customer, Order, Denormalized].each do |klass|
      Object.send(:remove_const, klass.to_s.to_sym)
    end
  
    ActiveRecord::Schema.define do
      ActiveRecord::Base.connection.tables.each do |old_table|
        drop_table old_table
      end
    end
  end
end
