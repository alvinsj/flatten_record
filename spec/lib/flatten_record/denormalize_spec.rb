require 'spec_helper'
require 'models/denormalize'

describe FlattenRecord::Denormalize do
  
  before :all do
    FlattenRecord::Denormalize::Test.setup_models
  end

  after :all do
    FlattenRecord::Denormalize::Test.delete_models
  end
  
  let(:klass) do
    klass = Class.new(ActiveRecord::Base)
    Object.send(:remove_const, :Denormalized) if Object.const_defined?(:Denormalized)
    Object.const_set('Denormalized', klass)
    Denormalized.class_eval do
      include FlattenRecord::Denormalize
    end
  end
 
  context 'is included' do  
    it 'should exists in Meta' do      
      expect(klass::Meta).to_not be_nil
      expect(klass::Meta.included_classes).to_not be_nil
      expect(klass::Meta.included_classes).to include(Denormalized.name)
    end
  end

  context 'is included with denormalize() definiton' do
    it 'should save the meta and add denormalize methods' do
      klass.class_eval do
        denormalize :target do|t| ;end
      end
      expect(klass.denormalizer_meta).to_not be_nil
      expect(klass.normal_model.name).to eql(Target.name)
      expect(klass).to respond_to(:create_denormalized)
      expect(klass).to respond_to(:destroy_denormalized)
    end
  end

end
