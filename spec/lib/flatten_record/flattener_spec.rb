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

    it 'responds the denormalization methods' do
      expect(Denormalized).to respond_to(:denormalize)
      expect(Denormalized).to respond_to(:create_denormalized)
      expect(Denormalized).to respond_to(:destroy_denormalized)
    end

    it 'build meta correctly' do
      klass.class_eval do
        
        def grand_total;end
        denormalize :order, {
          methods: [:grand_total],
          include: { customer: {} }
        }
        
      end
      meta = klass.flat_meta

      expect(klass.flat_meta).to_not be_nil
      
      column_names = meta.root.columns.map(&:name)
      expect(column_names).to be_include("total")
      expect(column_names).to be_include("customer_id")
      expect(column_names).to be_include("grand_total")
      expect(column_names).to be_include("customer_name")
    end
  end
end
