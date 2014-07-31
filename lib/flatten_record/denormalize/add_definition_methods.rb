module FlattenRecord
  module Denormalize
    module AddDefinitionMethods

      def denormalize(model, options={}, &block)
        root_options = options.merge(is_root: true, prefix: "d_") 

        self.denormalizer_meta = FlattenRecord::DenormalizerMeta.new(model, self, root_options)
        self.normal_model = model.to_s.camelize.constantize

        if block 
          yield denormalizer_meta
        else
          raise "block is required to specify fields for denormalization"
        end
        
        if !normal_model.respond_to?(:denormalized_models)
          normal_model.class_attribute :denormalized_models
          normal_model.denormalized_models ||= Array.new
          normal_model.denormalized_models << self
        end

        AddObservers.new(model, options).process(denormalizer_meta)

      end

      class AddObservers
        attr_accessor :denormalizer_meta
        
        def initialize(model, options)
          @options = options
          @model = model
        end
        
        def process(denormalizer_meta)
          @denormalizer_meta = denormalizer_meta
          observer = select_observer(@options, @model)
          active_record.observers ||= []  
          active_record.observers << observer unless active_record.observers.include?(observer)
        end

        protected 
        def child_models(meta, models=[])
          if meta
            models << meta.target_model
            meta.child_metas.each do |k, child_meta|
              models += child_models(child_meta, models)
            end
          end
          models
        end
  
        def active_record
          Rails.application.config.active_record
        end
  
        def normal_model
          denormalizer_meta.target_model
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
          observer_class.class_eval %Q{ def denormalized_model; #{denormalized_model.name}; end }
          observer_class.observe( [model]+child_models(meta) )
          observer_class.instance
  
          observer_class.name.underscore
        end

        def denormalized_model
          denormalizer_meta.target_denormalized_model
        end
  
        def model_observer(model, meta)
          observer_class = Class.new(FlattenRecord::Observer)
          observer_class.class_eval %Q{ def denormalized_model; #{denormalized_model.name}; end }
          observer_class.observe( [model]+child_models(meta) )
  
          observer_name = "#{denormalized_model.table_name.camelize}Observer" 
          
          # Override if previously defined
          if FlattenRecord.const_defined?(observer_name) 
            FlattenRecord.send(:remove_const, observer_name)
          end
  
          klass = FlattenRecord.const_set(observer_name,observer_class)
          klass.instance # initialize instance to make it work
  
          "flatten_record/#{observer_name}".underscore.to_sym
        end 
      end

    end # /AddDefinitionMethods
  end
end
