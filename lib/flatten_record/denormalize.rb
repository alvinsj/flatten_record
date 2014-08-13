module FlattenRecord
  module Denormalize
    
    class Meta
      class_attribute :included_classes
    end

    def self.included(base)
      Meta.included_classes ||= Array.new
      Meta.included_classes << base.name

      base.extend AddDefinitionMethods
      base.extend AddDenormalizationMethods

      base.class_eval do
        cattr_accessor :denormalizer_meta, :normal_model
        
        def refresh_denormalized
          parent_model_id = self.send(self.class.denormalizer_meta.id_column.name)
          self.class.create_denormalized(self.class.parent_model.find(parent_model_id))
        end
      end
    end
   
  end
end
