require 'spec_helper'
require 'support/flattener'

describe FlattenRecord::Flattener do

  context 'when included' do 
    before { FlattenRecord::Flattener::Test.setup_models }
    after { FlattenRecord::Flattener::Test.delete_models }
    
    it 'responds the denormalization methods' do
      expect(Denormalized).to respond_to(:denormalize)
      expect(Denormalized).to respond_to(:create_with)
    end
  end

  context "when denormalization is defined" do 
    before { FlattenRecord::Flattener::Test.setup_models }
    after { FlattenRecord::Flattener::Test.delete_models }

    let(:klass) do
      Order.class_eval do
        def grand_total
          50
        end
      end
      Child
      #raise Child.attribute_method?('name').inspect
      Denormalized.class_eval do    
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

      Denormalized 
    end

    let(:order_with_one_child) do
      child = Child.new(name: 'Ethan')
      child.cats << Cat.new(name: 'Meow')

      customer = Customer.create(name: 'Alvin') 
      customer.children << child
      
      order = Order.new
      order.total = 100
     
      order.customer = customer 
      order.save
      order
    end


    it 'build meta correctly' do
      meta = klass.flat_meta
      expect(meta).to_not be_nil
      
      expect(meta.root_node).to_not be_nil
      expect(meta.root_node.all_columns).to_not be_empty
      
      column_names = meta.root_node.all_columns.map(&:name) 

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
    end

    it 'is able to create denormalized record' do
      denormalized = klass.create_with(order_with_one_child) 
      expect(denormalized.count).to be_eql(1)

      record = denormalized.first
      
      expect(record.total).to be_eql(100)
      expect(record.grand_total).to be_eql(50)
      expect(record.total_in_usd).to be_eql(1000)
      expect(record.customer_name).to be_eql("Alvin")
      expect(record.customer_child_name).to be_eql("Ethan")
      expect(record.customer_child_cat_name).to be_eql("Meow")
    end
  end
end
