require 'spec_helper'
require 'support/root_node'

describe FlattenRecord::Meta::RootNode do
  before { FlattenRecord::Meta::RootNode::Test.setup_models }
  after { FlattenRecord::Meta::RootNode::Test.delete_models }
  
  let(:root_node) do
    FlattenRecord::Meta::RootNode.new(Order, Denormalized)
  end

  context ".build" do

    let(:definition) do
      definition_hash = { 
        include: { 
            customer: { 
              include: { 
                children: {
                  only: [:name],
                  include: { 
                    cats: {
                      only: [:name]
                    } 
                  }
                }
              }
            }
          },
        }
  
      FlattenRecord::Definition.new(definition_hash)
    end
   
    it "should construct the leaves" do
      root_node.build(definition)

      expect(root_node[:include]).to_not be_nil
      expect(root_node[:include].count).to eq(1)
      
      current_node = root_node
      [Order, Customer, Child, Cat].each do |klass|
         expect(current_node.target_model.to_s).to eq(klass.to_s)

         if klass != Cat
           expect(current_node[:include].count).to eq(1)
           current_node = current_node[:include].first[1]
         end
      end
    end

    it "should construct the leaves" do
      root_node.build(definition)

      expect(root_node[:include]).to_not be_nil
      expect(root_node[:include].count).to eq(1)
      
      current_node = root_node
      [Order, Customer, Child, Cat].each do |klass|
         expect(current_node.target_model.to_s).to eq(klass.to_s) 
         current_node = current_node[:include].blank? ? nil : current_node[:include].first[1]
      end
    end
 
  end # /.build

  context ".traverse" do
    let(:definition) do
      definition_hash = { 
        include: { 
            customer: { 
              include: { 
                children: {
                  only: [:name],
                  include: { 
                    cats: {
                      only: [:name]
                    } 
                  }
                }
              }
            }
          },
        }
  
      FlattenRecord::Definition.new(definition_hash)
    end
    
    let(:new_root_node) do
      root_node.build(definition)
      root_node
    end
    
    it 'traverse to node' do
      [Order, Customer, Child, Cat].each do |klass|
        node = new_root_node.traverse_by(:target_model, klass)
        expect(node).to_not be_nil
        expect(node.target_model.to_s).to eq(klass.to_s)
      end
    end
  end
 
end
