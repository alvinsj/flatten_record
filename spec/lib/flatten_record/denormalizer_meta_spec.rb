require 'spec_helper'

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :orders do |t|
      t.integer :total
      t.integer :customer_id
    end
    create_table :customers do |t|
      t.string :name
      t.integer :child_id
    end
    create_table :children do |t|
      t.string :name
      t.integer :total
    end
    create_table :cats do |t|
      t.string :name
      t.string :owner_type
      t.integer :owner_id
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
    class Cat < ActiveRecord::Base; belongs_to :owner, polymorphic: true ; end
    class Child < ActiveRecord::Base; has_many :cats; has_many :cats, as: :other_pets ; end
    class Customer < ActiveRecord::Base; belongs_to :child; end 
    class Order < ActiveRecord::Base; belongs_to :customer;end
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
        denormalize :order do |order|
          order.denormalize :customer
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count  
      customer_col_count = Customer.columns.count 
      expect(meta.denormalized_columns.count).to eq(order_col_count+customer_col_count)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('d_customer_customer_id')
      expect(columns).to include('d_customer_name')
    end
  end

  context "when nested(x2) denormalize() is defined " do
    it 'should have the target+nested_target+child model columns ' do
      klass.class_eval do
        denormalize :order do |order|
          order.denormalize :customer do |customer|
            customer.denormalize :child
          end
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count  
      customer_col_count = Customer.columns.count
      child_col_count = Child.columns.count
      expect(meta.denormalized_columns.count).
        to eq(order_col_count+customer_col_count+child_col_count)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('d_customer_child_child_id')
      expect(columns).to include('d_customer_child_total')
    end
  end

  context "when save() is defined " do
    it 'should have the custom columns ' do
      klass.class_eval do
        denormalize :order do |order|
          order.save :custom_field_1, :integer
          order.denormalize :customer do |customer|
            customer.save :custom_field_2, :integer
            customer.denormalize :child
          end
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count  
      customer_col_count = Customer.columns.count
      child_col_count = Child.columns.count
      expect(meta.denormalized_columns.count).
        to eq(order_col_count+customer_col_count+child_col_count+2)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('custom_field_1')
      expect(columns).to include('d_customer_custom_field_2')
    end
  end

end

