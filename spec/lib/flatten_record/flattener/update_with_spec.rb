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
      
      customer = Customer.create(name: 'Alvin') 
      customer.children << child1
      customer.children << child2
      
      order = Order.new
      order.total = 100
     
      order.customer = customer 
      order.save
      order
    end

    context '.update_with' do
      it 'should be able to update related records' do 
        order = order_with_customer_with_one_child
        order.total = 1000
        order.save

        denormalized = klass.create_with(order) 
        expect(klass.count).to eq(1)
  
        record = denormalized.first
        expect(record.total).to eq(1000)

        # change attribute
        order.total = 2000
        order.save

        changed = klass.update_with(order) 
        expect(klass.count).to eq(1)
        
        record = changed.first
        
        expect(record.total).to eq(2000)
      end

      it 'should be able to update related records' do 
        order = order_with_customer_with_one_child

        denormalized = klass.create_with(order) 
        expect(klass.count).to eq(1)
  
        record = denormalized.first
        expect(record.customer_child_cat_name).to eq("Meow")
        
        # change child attribute
        cat = order.customer.children.first.cats.first
        cat.name = "Phew"
        cat.save

        changed = klass.update_with(order) 
        expect(klass.count).to eq(1)
        
        record = changed.first
        expect(record.customer_child_cat_name).to eq("Phew")
      end

      it 'should be able to update related records' do 
        order = order_with_customer_with_two_children

        denormalized = klass.create_with(order) 
        expect(klass.count).to eq(2)
  
        record = denormalized.first
        expect(record.customer_child_cat_name).to eq("Meow")
        
        # change child attribute
        cat = order.customer.children.first.cats.first
        cat.name = "Phew"
        cat.save

        order.customer.children.create(name: "Starlord")
        
        changed = klass.update_with(order.reload) 
        expect(klass.count).to eq(3)
        
        record = changed.first
        expect(record.customer_child_cat_name).to eq("Phew")
      end


    end #/.update_with
  end
end
