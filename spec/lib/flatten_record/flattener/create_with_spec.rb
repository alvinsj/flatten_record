require 'spec_helper'
require 'support/flattener'

describe FlattenRecord::Flattener do

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

    let(:order_with_customer_with_two_children) do
      child1 = Child.new(name: 'Ethan')
      child1.cats << Cat.new(name: 'Meow')

      child2 = Child.new(name: 'Yan')
      
      customer = Customer.create(name: 'Alvin') 
      customer.children << child1
      customer.children << child2
      
      order = Order.new
      order.total = 100
     
      order.customer = customer 
      order.save
      order
    end

    let(:order_with_customer_with_two_children_nested) do
      child1 = Child.new(name: 'Ethan')
      child1.cats << Cat.new(name: 'Meow')
      child1.cats << Cat.new(name: 'Phew')

      child2 = Child.new(name: 'Yan')
      child2.cats << Cat.new(name: "Octocat")
      child2.cats << Cat.new(name: "Tender")
      
      customer = Customer.create(name: 'Alvin') 
      customer.children << child1
      customer.children << child2
      
      order = Order.new
      order.total = 100
     
      order.customer = customer 
      order.save
      order
    end

    context '.create_with' do
      it 'should be able to create denormalized record' do
        denormalized = klass.create_with(order_with_customer_with_one_child) 
        expect(denormalized.count).to eq(1)
  
        record = denormalized.first
        
        expect(record.total).to eq(100)
        expect(record.grand_total).to eq(50)
        expect(record.total_in_usd).to eq(1000)
        expect(record.customer_name).to eq("Alvin")
        expect(record.customer_child_name).to eq("Ethan")
        expect(record.customer_child_cat_name).to eq("Meow")
      end

      it 'should be able to create multiple denormalized records (:has_many)' do
        denormalized = klass.create_with(order_with_customer_with_two_children) 
        expect(denormalized.count).to eq(2)
        record = denormalized[0]
        
        expect(record.customer_child_name).to eq("Ethan")
        expect(record.customer_child_cat_name).to eq("Meow")
 
        record = denormalized[1]
        
        expect(record.customer_child_name).to eq("Yan")
        expect(record.customer_child_cat_name).to be_nil
      end

      it 'should be able to create multiple denormalized records (nested :has_many)' do
        denormalized = klass.create_with(order_with_customer_with_two_children_nested) 
        expect(denormalized.count).to eq(4)
        record = denormalized[0]
        
        expect(record.customer_child_name).to eq("Ethan")
        expect(record.customer_child_cat_name).to eq("Meow")
 
        record = denormalized[1]
        
        expect(record.customer_child_name).to eq("Ethan")
        expect(record.customer_child_cat_name).to eq("Phew")
        
        record = denormalized[2]
        
        expect(record.customer_child_name).to eq("Yan")
        expect(record.customer_child_cat_name).to eq("Octocat")
 
        record = denormalized[3]
        
        expect(record.customer_child_name).to eq("Yan")
        expect(record.customer_child_cat_name).to eq("Tender")
 
      end

    end #/.create_with
  end
end
