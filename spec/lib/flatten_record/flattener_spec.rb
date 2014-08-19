require 'spec_helper'
require 'support/flattener'

describe FlattenRecord::Flattener do

  context 'when included' do 
    before { FlattenRecord::Flattener::Test.setup_models }
    after { FlattenRecord::Flattener::Test.delete_models }
    
    it 'should respond to the helper methods' do
      expect(Denormalized).to respond_to(:denormalize)
      expect(Denormalized).to respond_to(:create_with)
      expect(Denormalized).to respond_to(:update_with)
      expect(Denormalized).to respond_to(:destroy_with)
      expect(Denormalized).to respond_to(:find_with)
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
      
      Denormalized.class_eval do    
        denormalize :order, {
          compute: [:total_in_usd],
          methods: [:grand_total],
          include: { 
            customer: { 
              include: { 
                children: {
                  only: [:name],
                  include: { 
                    cats: {
                      only: [:name],
                      include: { 
                        owner: { class_name: 'Child', only: [:name] } 
                      }
                    } 
                  }
                }
              }
            }
          },
        }
        def compute_total_in_usd(item)
          1000
        end
      end

      Denormalized 
    end

    let(:order_with_customer_with_one_child) do
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

    context '.find_with' do
      it 'should be able to find related records' do 
        denormalized = klass.create_with(order_with_customer_with_one_child) 
        records = klass.find_with(order_with_customer_with_one_child.customer)
        expect(records.count).to eq(1)
  
        record = records.first
        
        expect(record.total).to eq(100)
        expect(record.grand_total).to eq(50)
        expect(record.total_in_usd).to eq(1000)
        expect(record.customer_name).to eq("Alvin")
        expect(record.customer_child_name).to eq("Ethan")
        expect(record.customer_child_cat_name).to eq("Meow")
        
      end
    end #/.find_with


    context '.destroy_with' do
      it 'should be able to destroy related records' do 
        denormalized = klass.create_with(order_with_customer_with_one_child) 
        expect(klass.count).to eq(1)
  
        klass.destroy_with(order_with_customer_with_one_child)
        expect(klass.count).to eq(0)
      end
    end #/.find_with

  
  end
end
