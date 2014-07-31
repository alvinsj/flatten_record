module FlattenRecord
  module Denormalize
    module AddDenormalizationMethods

      def self.included(base)
        raise "denormalizer_meta is not defined" unless base.respond_to?(:denormalizer_meta)
      end
      
      def create_denormalized(normal_instance)
        if normal_instance.class.name == normal_model.name
          records = self.where("#{denormalizer_meta.id_column.name} = ?", normal_instance.id)
          records.each{|r| r.destroy}
          DenormalizeParent.new(normal_instance, denormalizer_meta).process
        
        else
          ids = DestroyRelatedDenormalized.new(normal_instance, denormalizer_meta).process
          
          normal_model.where(id: ids).each do |instance|
            DenormalizeParent.new(instance, denormalizer_meta).process
          end
        end
      end

      def destroy_denormalized(normal_instance)
        if normal_instance.class.name == normal_model.name        
          ActiveRecord::Base.transaction do 
            records = self.where("#{denormalizer_meta.id_column.name} = ?", normal_instance.id)
            records.each{|r| r.destroy}
          end
        else
          DestroyRelatedDenormalized.new(normal_instance, denormalizer_meta).process
        end
      end

      def normal_model
        denormalizer_meta.normal_model
      end
      
      class DenormalizeParent
        def initialize(normal_instance, denormalizer_meta)
          @normal = normal_instance
          @meta = denormalizer_meta
        end

        def process
          denormalizer = FlattenRecord::Denormalizer.new(@meta, @normal)
          record_s = denormalizer.denormalize_record
          record_s.instance_of?(Array) ? record_s.each(&:save) : record_s.save
        end
      end # /DenormalizeParent
       
      class DestroyRelatedDenormalized
        def initialize(normal_instance, denormalizer_meta)
          @normal = normal_instance
          @meta = denormalizer_meta
        end
      
        def process
          field_name = denormalized_field(@normal.class.name, @meta)
          raise "field name cannot be found." if field_name.nil?
        
          records = denormalized_class.where("#{field_name} = ?", @normal.id)
          ids = records.map{ |r| r.send(@meta.id_column.name)}.uniq unless records.empty?
          records.each{|r| r.destroy}
          ids
        end
        
        protected
        def denormalized_class
          @meta.denormalized_model
        end

        def denormalized_field(normal, meta)
          return "#{meta.prefix}#{meta.id_column.name}" if meta.normal_model.name == normal
          field = nil
          meta.children.each do |child_name,child| 
            temp = denormalized_field(normal, child)
            field = temp if temp 
          end
          field
        end
      end # /DestroyRelatedDenormalized

    end
  end
end
