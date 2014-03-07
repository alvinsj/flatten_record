module FlattenRecord
  module Denormalize
    extend ActiveSupport::Concern
    
    class Meta
      class_attribute :included_classes
    end

    def self.included(base)
      Meta.included_classes ||= Array.new
      Meta.included_classes << base.name
    end

    module ClassMethods 
      def denormalize(model, &block)
        @@denormalizer_meta = FlattenRecord::DenormalizerMeta.new(model, self, prefix: "d_")
        @@parent_model = model.to_s.camelize.constantize
        if block 
          yield @@denormalizer_meta
        else
          raise "block is required to specify fields for denormalization"
        end
        
        klass = self
        if !@@parent_model.respond_to?(:denormalized_models)
          @@parent_model.class_attribute :denormalized_models
          @@parent_model.denormalized_models ||= Array.new
          @@parent_model.denormalized_models << klass
        end
        @@parent_model.send :include, FlattenRecord::DenormalizerHook 
      end
      
      def denormalizer_meta
        @@denormalizer_meta
      end

      def parent_model
        @@parent_model
      end

      def create_denormalized(normal_instance)
#        ActiveRecord::Base.transaction do
          records = self.where("#{self.denormalizer_meta.id_column.name} = ?", normal_instance.id)
          records.each{|r| r.destroy}
          denormalizer = FlattenRecord::Denormalizer.new(self.denormalizer_meta, normal_instance, "")
          record_s = denormalizer.denormalize_record
          if record_s.instance_of?(Array)
            record_s.each{|r| r.save}
          else
            record_s.save
          end
 #       end
      end

      def destroy_denormalized(normal_instance)
        ActiveRecord::Base.transaction do 
          records = self.where("#{self.denormalizer_meta.id_column.name} = ?", normal_instance.id)
          records.each{|r| r.destroy}
        end
      end
    end # /ClassMethods

  end
end
