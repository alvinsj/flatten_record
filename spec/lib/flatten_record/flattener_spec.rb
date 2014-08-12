require 'spec_helper'
require 'models/flattener'

describe FlattenRecord::Flattener do
  context 'when included' do
    before :all do
      FlattenRecord::Flattener::Test.setup_models
    end

    after :all do 
      FlattenRecord::Flattener::Test.delete_models
    end

    let(:klass) { Denormalized } 
    let(:order) do
      order = Order.new
      order.total = 100
      customer = Customer.create(name: 'Alvin') 
      customer.children << Child.create(name: 'Ethan')
      order.customer = customer 
      order.save
      order
    end

    it 'responds the denormalization methods' do
      expect(Denormalized).to respond_to(:denormalize)
      expect(Denormalized).to respond_to(:create_with)
      expect(Denormalized).to respond_to(:destroy_with)
    end

    it 'build meta correctly' do
      Order.class_eval do
        def grand_total
          50
        end
      end

      klass.class_eval do    
        denormalize :order, {
          compute: [:total_in_usd],
          methods: [:grand_total],
          include: { 
            customer: { 
              include: { 
                children: {
                  only: [:name],
                  include: { cats: {only: [:name]} }
                }
              }
            }
          },
        }
        def total_in_usd
          1000
        end
      end
      meta = klass.flat_meta

      expect(klass.flat_meta).to_not be_nil
      
      column_names = meta.root.all_columns.map(&:name)
      
      expect(column_names.count).to be_eql(10)

      expect(column_names).to be_include("order_id")
      expect(column_names).to be_include("total")
      expect(column_names).to be_include("customer_id")
      expect(column_names).to be_include("grand_total")
      expect(column_names).to be_include("total_in_usd")
      expect(column_names).to be_include("customer_id")
      expect(column_names).to be_include("customer_child_id")
      expect(column_names).to be_include("customer_child_name")
      expect(column_names).to be_include("customer_child_cat_id")
      expect(column_names).to be_include("customer_child_cat_name")
     
      #raise meta.root.denormalize(order, klass.new).inspect
    end

    
  end
end
