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
      @@denormalizer_meta = nil 
      def denormalize(model, &block)
        @@denormalizer_meta = FlattenRecord::DenormalizerMeta.new(model, self, is_root: true, prefix: "d_")
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
        Rails.application.config.active_record.observers ||= []  
        Rails.application.config.active_record.observers << model_observer(model, @@denormalizer_meta)
        #@@parent_model.send :include, FlattenRecord::DenormalizerHook 
      end

      def model_observer(model, meta)
        observer_class = Class.new(FlattenRecord::Observer) 
        observer_class.class_eval %Q{ def denormalized_model; #{self.name}; end }
        observer_class.observe( [model]+child_models(meta) )

        observer_name = "#{self.table_name.camelize}Observer" 
        klass = FlattenRecord.const_set(observer_name,observer_class)
        klass.instance # initialize instance to make it work

        "flatten_record/#{observer_name}".underscore.to_sym
      end

      def child_models(meta, models=[])
        if meta
          models << meta.normal_model
          meta.children.each do |k, child_meta|
            models += child_models(child_meta, models)
          end
        end
        models
      end

      def denormalizer_meta
        @@denormalizer_meta
      end

      def parent_model
        @@parent_model
      end

      def create_denormalized(normal_instance)

        if normal_instance.class.name == self.denormalizer_meta.normal_model.name
          records = self.where("#{self.denormalizer_meta.id_column.name} = ?", normal_instance.id)
          records.each{|r| r.destroy}
          denormalize_parent(normal_instance)
        
        else 
          field_name = denormalized_field(normal_instance.class.name, self.denormalizer_meta)
          records = self.where("#{field_name} = ?", normal_instance.id)
          ids = records.map{ |r| r.send(self.denormalizer_meta.id_column.name)}.uniq unless records.empty?
          records.each{|r| r.destroy}
          
          self.denormalizer_meta.normal_model.where(id: ids).each do |i|
            denormalize_parent(i)
          end
        end
        
      end
      
      def denormalize_parent(normal_instance)
        denormalizer = FlattenRecord::Denormalizer.new(self.denormalizer_meta, normal_instance)
        record_s = denormalizer.denormalize_record
        record_s.instance_of?(Array) ? record_s.each{|r| r.save} : record_s.save
      end

      def denormalized_field(normal, meta)
        return "#{meta.prefix}#{meta.model_sym.to_s}_#{meta.id_column.name}" if meta.normal_model.name == normal
        field = nil
        meta.children.each do |k,v| 
          temp = denormalized_field(normal, v)
          field = temp if temp 
        end
        field
      end

      def destroy_denormalized(normal_instance)
        if normal_instance.class.name == self.denormalizer_meta.normal_model.name        
          ActiveRecord::Base.transaction do 
            records = self.where("#{self.denormalizer_meta.id_column.name} = ?", normal_instance.id)
            records.each{|r| r.destroy}
          end
        else
          field_name = denormalized_field(normal_instance.class.name, self.denormalizer_meta)
          records = self.where("#{field_name} = ?", normal_instance.id)
          ids = records.map{ |r| r.send(self.denormalizer_meta.id_column.name)}.uniq unless records.empty?
          records.each{|r| r.destroy}

          self.denormalizer_meta.normal_model.where(id: ids).each do |i|
            denormalize_parent(i)
          end
        end
      end
    end # /ClassMethods

  end
end
