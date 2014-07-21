require 'spec_helper'
require 'models/denormalizer_meta'

describe FlattenRecord::DenormalizerMeta do 
  before :all do
    FlattenRecord::DenormalizerMeta::Test.setup_models
  end

  after :all do
    FlattenRecord::DenormalizerMeta::Test.delete_models
  end

  let(:klass) do
    Denormalized
  end

  context "when denormalize() is defined" do
    it 'should have the target model columns' do
      klass.class_eval do

        denormalize :order do |order|
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count     
      expect(meta.denormalized_columns.count).to eq(order_col_count)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('order_id')
      expect(columns).to include('total')
    end
  end

  context "when denormalize() with option[:except] is defined" do
    it 'should have the target model columns' do
      klass.class_eval do
        denormalize :order, except: [:total] do |order|
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count     
      expect(meta.denormalized_columns.count).to eq(order_col_count-1)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).not_to include('total')
    end
  end

  context "when denormalize() with option[:only] is defined" do
    it 'should have the target model columns' do
      klass.class_eval do
        denormalize :order, only: [:order_id] do |order|
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count     
      expect(meta.denormalized_columns.count).to eq(1)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('order_id')
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
            customer.denormalize :children
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
      expect(columns).to include('d_customer_children_child_id')
      expect(columns).to include('d_customer_children_name')
    end
  end

  context "when save() is defined " do
    it 'should have the custom columns ' do
      klass.class_eval do
        denormalize :order do |order|
          order.save :custom_field_1, :integer
          order.denormalize :customer do |customer|
            customer.save :custom_field_2, :integer
          end
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count  
      customer_col_count = Customer.columns.count
      custom_col_count = 2
      expect(meta.denormalized_columns.count).
        to eq(order_col_count+customer_col_count+custom_col_count)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('custom_field_1')
      expect(columns).to include('d_customer_custom_field_2')
    end
  end

  context "when polymorphic is defined " do
    it 'should have the proper named model columns ' do
      klass.class_eval do
        denormalize :order do |order|
          order.denormalize :customer do |customer|
            customer.denormalize :cats, as: :cat
          end
        end
      end
      meta = klass.denormalizer_meta
  
      order_col_count = Order.columns.count  
      customer_col_count = Customer.columns.count 
      cat_col_count = Cat.columns.count 
      expect(meta.denormalized_columns.count).to eq(order_col_count+customer_col_count+cat_col_count)
     
      columns = meta.denormalized_columns.collect(&:name) 
      expect(columns).to include('d_customer_customer_id')
      expect(columns).to include('d_customer_name')
      expect(columns).to include('d_customer_cats_name')
      expect(columns).to include('d_customer_cats_owner_type')
      expect(columns).to include('d_customer_cats_owner_id')
    end
  end

end

