require 'spec_helper'
require 'models/denormalizer'

describe FlattenRecord::Denormalizer do
  
  before :all do
    FlattenRecord::Denormalizer::Test.setup_models
  end

  after :each do
    Denormalized.destroy_all
  end

  after :all do
    Denormalized.destroy_all
    FlattenRecord::Denormalizer::Test.delete_models
  end


  context "when target is destroyed with data" do 
    it 'should also destroy the target data' do
      @order = Order.new
      @order.total = 101
      @order.save!
      
      denormalized = Denormalized.first 
      expect(denormalized).to_not be_nil
      expect(denormalized.order_id).to eq(@order.id)
      expect(denormalized.total).to eq(@order.total)
      
      @order.destroy
      denormalized = Denormalized.first 
      expect(denormalized).to be_nil
    end
  end

end

describe FlattenRecord::Denormalizer do
  
  before :all do
    FlattenRecord::Denormalizer::Test.setup_models
  end

  after :each do
    Denormalized.destroy_all
  end

  after :all do
    Denormalized.destroy_all
    FlattenRecord::Denormalizer::Test.delete_models
  end

  context "when target is saved with data" do 
    it 'should save the target data' do
      @order = Order.new
      @order.total = 101
      @order.save!
      
      expect(Denormalized.count).to eql(1)
      denormalized = Denormalized.first 
      expect(denormalized).to_not be_nil
      expect(denormalized.order_id).to eq(@order.id)
      expect(denormalized.total).to eq(@order.total)
    end
  end

  context "when target is saved with child(belongs_to:) data" do
    it 'should save the child data' do
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin")
      @order.save

      denormalized = Denormalized.first 
      
      expect(denormalized).to_not be_nil
      expect(denormalized.d_customer_name).to eql("alvin")
    end
  end

  context "when target is saved with children(:has_many) data" do
    it 'should save the custom column data' do
      @child1 = Child.create(name: 'chloe')
      @child2 = Child.create(name: 'oliver')
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin")
      @order.customer.children << @child1
      @order.customer.children << @child2
      @order.save

      denormalized1 = Denormalized.first
      denormalized2 = Denormalized.last
      
      expect(denormalized1).to_not be_nil
      expect(Denormalized.all.count).to eq(2)
      expect(denormalized1.d_customer_children_name).to eq(@child1.name)
      expect(denormalized2.d_customer_children_name).to eq(@child2.name)
    end
  end

  context "when target is saved with custom data" do
    it 'should save the custom column data' do
      @child = Child.create(name: 'chloe')
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin", children: [@child])
      @order.save

      denormalized = Denormalized.first

      expect(denormalized).to_not be_nil
      expect(denormalized.d_customer_number_of_children).to eq(@order.customer.children.count)
    end
  end

  context "when polymorphic association is saved" do
    it 'should save the polymorphic association' do
      @cat1 = Cat.create(name: 'meow')
      @cat2 = Cat.create(name: 'pea')
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin", cats: [@cat1, @cat2])
      @order.save
      denormalized1 = Denormalized.first
      denormalized2 = Denormalized.last
       
      expect(denormalized1).to_not be_nil
      expect(Denormalized.all.count).to eq(2)
      expect(denormalized1.d_customer_cats_name).to eq(@cat1.name)
      expect(denormalized2.d_customer_cats_name).to eq(@cat2.name)
    end
  end

end

