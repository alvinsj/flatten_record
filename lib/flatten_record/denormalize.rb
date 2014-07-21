module FlattenRecord
  module Denormalize
    extend ActiveSupport::Concern
    
    class Meta
      class_attribute :included_classes
    end

    def self.included(base)
      Meta.included_classes ||= Array.new
      Meta.included_classes << base.name
      base.class_eval do
        cattr_accessor :denormalizer_meta, :parent_model
      end
    end

    module ClassMethods 
      def denormalize(model, options={}, &block)
        root_options = options.merge(is_root: true, prefix: "d_") 

        self.denormalizer_meta = FlattenRecord::DenormalizerMeta.new(model, self, root_options)
        self.parent_model = model.to_s.camelize.constantize

        if block 
          yield denormalizer_meta
        else
          raise "block is required to specify fields for denormalization"
        end
        
        if !parent_model.respond_to?(:denormalized_models)
          parent_model.class_attribute :denormalized_models
          parent_model.denormalized_models ||= Array.new
          parent_model.denormalized_models << self
        end

        observer = select_observer(options, model)
        active_record.observers ||= []  
        active_record.observers << observer unless active_record.observers.include?(observer)
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

      def create_denormalized(normal_instance)
        if normal_instance.class.name == normal_model.name
          records = self.where("#{denormalizer_meta.id_column.name} = ?", normal_instance.id)
          records.each{|r| r.destroy}
          denormalize_parent(normal_instance)
        
        else
          ids = destroy_related_denormalized(normal_instance)
          
          normal_model.where(id: ids).each do |i|
            denormalize_parent(i)
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
          destroy_related_denormalized(normal_instance)
        end
      end

      private 
      def active_record
        Rails.application.config.active_record
      end

      def normal_model
        denormalizer_meta.normal_model
      end
            
      def select_observer(options, model)
        if options[:observer]
          begin 
            custom_observer(options[:observer], model, denormalizer_meta)
          rescue
            raise "Custom Observer class initialization failed."
          end
        else
          model_observer(model, denormalizer_meta)
        end
      end

      def custom_observer(observer_class, model, meta)
        observer_class.class_eval %Q{ def denormalized_model; #{self.name}; end }
        observer_class.observe( [model]+child_models(meta) )
        observer_class.instance

        observer_class.name.underscore
      end

      def model_observer(model, meta)
        observer_class = Class.new(FlattenRecord::Observer)
        observer_class.class_eval %Q{ def denormalized_model; #{self.name}; end }
        observer_class.observe( [model]+child_models(meta) )

        observer_name = "#{self.table_name.camelize}Observer" 
        
        # Override if previously defined
        if FlattenRecord.const_defined?(observer_name) 
          FlattenRecord.send(:remove_const, observer_name)
        end

        klass = FlattenRecord.const_set(observer_name,observer_class)
        klass.instance # initialize instance to make it work

        "flatten_record/#{observer_name}".underscore.to_sym
      end

      def denormalize_parent(normal_instance)
        denormalizer = FlattenRecord::Denormalizer.new(denormalizer_meta, normal_instance)
        
        record_s = denormalizer.denormalize_record
        record_s.instance_of?(Array) ? record_s.each{|r| r.save} : record_s.save
      end

      def denormalized_field(normal, meta)
        return "#{meta.prefix}#{meta.id_column.name}" if meta.normal_model.name == normal
        field = nil
        meta.children.each do |k,v| 
          temp = denormalized_field(normal, v)
          field = temp if temp 
        end
        field
      end

      def destroy_related_denormalized(normal_instance)
        field_name = denormalized_field(normal_instance.class.name, denormalizer_meta)
        raise "field name cannot be found." if field_name.nil?
        
        records = self.where("#{field_name} = ?", normal_instance.id)
        ids = records.map{ |r| r.send(denormalizer_meta.id_column.name)}.uniq unless records.empty?
        records.each{|r| r.destroy}
        ids
      end
    end # /ClassMethods
    
    def refresh_denormalized
      parent_model_id = self.send(self.class.denormalizer_meta.id_column.name)
      self.class.create_denormalized(self.class.parent_model.find(parent_model_id))
    end
  end
end
