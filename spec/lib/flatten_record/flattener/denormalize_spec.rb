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

  context ".denormalize" do 
    before { FlattenRecord::Flattener::Test.setup_models }
    after { FlattenRecord::Flattener::Test.delete_models }
   
    context 'when denormalization options is defined' do
      let(:klass) do
        Order.class_eval { def grand_total;50;end }
        
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
          def compute_total_in_usd(item);1000;end
        end
  
        Denormalized 
      end
   
      it 'should construct columns' do
        meta = klass.flattener_meta
        expect(meta).to_not be_nil 
        
        expect(meta.all_columns).to_not be_empty
        column_names = meta.all_columns.map(&:name) 
  
        expect(column_names.count).to eq(12)
  
        expect(column_names).to be_include("order_id")
        expect(column_names).to be_include("total")
        expect(column_names).to be_include("grand_total")
        expect(column_names).to be_include("total_in_usd")
        expect(column_names).to be_include("customer_id")
        expect(column_names).to be_include("customer_name")
        expect(column_names).to be_include("customer_child_id")
        expect(column_names).to be_include("customer_child_name")
        expect(column_names).to be_include("customer_child_cat_id")
        expect(column_names).to be_include("customer_child_cat_name")
        expect(column_names).to be_include("customer_child_cat_owner_child_id")
        expect(column_names).to be_include("customer_child_cat_owner_child_name")
      end
    end #/context

    context 'when :prefix is defined' do
      let(:klass) do
        Order.class_eval { def grand_total;50;end }
        
        Denormalized.class_eval do    
          denormalize :order, {
            compute: [:total_in_usd],
            methods: [:grand_total],
            include: { 
              customer: {
                prefix: 'cs_',
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
          def compute_total_in_usd(item);1000;end
        end
  
        Denormalized 
      end
 
      it 'should contruct columns with prefix' do 
        meta = klass.flattener_meta   
        meta = klass.flattener_meta
        expect(meta).to_not be_nil 
        
        expect(meta.all_columns).to_not be_empty
        column_names = meta.all_columns.map(&:name) 
  
        expect(column_names.count).to eq(12)
  
        expect(column_names).to be_include("order_id")
        expect(column_names).to be_include("total")
        expect(column_names).to be_include("grand_total")
        expect(column_names).to be_include("total_in_usd")
        expect(column_names).to be_include("cs_id")
        expect(column_names).to be_include("cs_name")
        expect(column_names).to be_include("cs_child_id")
        expect(column_names).to be_include("cs_child_name")
        expect(column_names).to be_include("cs_child_cat_id")
        expect(column_names).to be_include("cs_child_cat_name")
        expect(column_names).to be_include("cs_child_cat_owner_child_id")
        expect(column_names).to be_include("cs_child_cat_owner_child_name")

      end
    end #/context
   
    context 'when :except option is defined' do
      let(:klass) do
        Order.class_eval { def grand_total;50;end }
        
        Denormalized.class_eval do    
          denormalize :order, {
            compute: [:total_in_usd],
            methods: [:grand_total],
            include: { 
              customer: { 
                include: { 
                  children: {
                    except: [:name],
                    include: { 
                      cats: {
                        except: [:name],
                        include: { 
                          owner: { class_name: 'Child', except: [:name] } 
                        }
                      } 
                    }
                  }
                }
              }
            },
          }
          def compute_total_in_usd(item);1000;end
        end
  
        Denormalized 
      end
   
      it 'should construct columns' do
        meta = klass.flattener_meta
        expect(meta).to_not be_nil 
        
        expect(meta.all_columns).to_not be_empty
        column_names = meta.all_columns.map(&:name) 
  
        expect(column_names.count).to eq(15)
  
        expect(column_names).to be_include("order_id")
        expect(column_names).to be_include("total")
        expect(column_names).to be_include("grand_total")
        expect(column_names).to be_include("total_in_usd")
        expect(column_names).to be_include("customer_id")
        expect(column_names).to be_include("customer_name")
        expect(column_names).to be_include("customer_child_id")
        expect(column_names).to be_include("customer_child_parent_id")
        expect(column_names).to be_include("customer_child_description")
        expect(column_names).to be_include("customer_child_cat_id")
        expect(column_names).to be_include("customer_child_cat_description")
        expect(column_names).to be_include("customer_child_cat_owner_type")
        expect(column_names).to be_include("customer_child_cat_owner_child_id")
        expect(column_names).to be_include("customer_child_cat_owner_child_parent_id")
        expect(column_names).to be_include("customer_child_cat_owner_child_description")
      end
    end #/context




  end
end
