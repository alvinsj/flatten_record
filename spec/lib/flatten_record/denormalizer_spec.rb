require 'spec_helper'

def setup_db_for_denormalizer
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
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
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end


describe FlattenRecord::DenormalizerMeta do
  before do
    setup_db_for_denormalizer
    class Cat < ActiveRecord::Base; belongs_to :owner, polymorphic: true ; end
    class Child < ActiveRecord::Base; belongs_to :customer; has_many :cats, as: :owner; end
    class Customer < ActiveRecord::Base; has_many :children, class_name: Child; has_many :cats, as: :owner; end 
    class Order < ActiveRecord::Base; belongs_to :customer;end
    
    class Denormalized < ActiveRecord::Base
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
  end

  after do 
    teardown_db
  end

  context "when target is saved with data" do
    before do
      @order = Order.new
      @order.total = 100
      @order.save
    end
      
    it 'should save the target data' do
      denormalized = Denormalized.first 
      expect(denormalized.order_id).to eq(@order.id)
      expect(denormalized.total).to eq(@order.total)
    end
  end

  context "when target is saved with child(belongs_to:) data" do
    before do
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin")
      @order.save
    end

    it 'should save the child data ' do
      denormalized = Denormalized.first 
      expect(denormalized.d_customer_name).to eql("alvin")
    end
  end

  context "when target is saved with children(:has_many) data" do
    before do
      @child1 = Child.create(name: 'chloe')
      @child2 = Child.create(name: 'oliver')
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin")
      @order.customer.children << @child1
      @order.customer.children << @child2
      @order.save
    end

    it 'should save the custom column data' do
      denormalized1 = Denormalized.first
      denormalized2 = Denormalized.last
      
      expect(Denormalized.all.count).to eq(2)
      expect(denormalized1.d_customer_children_name).to eq(@child1.name)
      expect(denormalized2.d_customer_children_name).to eq(@child2.name)
    end
  end

  context "when target is saved with custom data" do
    before do
      @child = Child.create(name: 'chloe')
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin", children: [@child])
      @order.save
    end
    it 'should save the custom column data' do
      denormalized = Denormalized.first
      expect(denormalized.d_customer_number_of_children).to eq(@order.customer.children.count)
    end
  end

  context "when polymorphic association is saved" do
    before do
      @cat1 = Cat.create(name: 'meow')
      @cat2 = Cat.create(name: 'pea')
      @order = Order.new
      @order.customer = Customer.create!(name: "alvin", cats: [@cat1, @cat2])
      @order.save
    end
    it 'should save the polymorphic association' do
      denormalized1 = Denormalized.first
      denormalized2 = Denormalized.last
       
      expect(Denormalized.all.count).to eq(2)
      expect(denormalized1.d_customer_cats_name).to eq(@cat1.name)
      expect(denormalized2.d_customer_cats_name).to eq(@cat2.name)
    end
  end

end

