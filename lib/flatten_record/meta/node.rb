module FlattenRecord
  module Meta
    class Node
      attr_reader :parent, :children, :target_model, :model

      def initialize(parent, target_model, model)
        @parent = parent
        @target_model = target_model.to_s.underscore
        @model = model.to_s.underscore
      end

      def target_model
        @target_model.camelize.constantize 
      end

      def model
        @model.camelize.constantize
      end

      def traverse_by(attr, value)
        attr_value = send("#{attr}")

        if !value.respond_to?(:to_s) || !attr_value.respond_to?(:to_s)
          raise "traverse error: to_s method required for comparison"
        end
 
        if value.to_s.downcase == attr_value.to_s.downcase
          return self
        else 
          return nil
        end
      end
 
      def prefix
        return custom_prefix unless custom_prefix.nil?
        return "" if is_parent_root?
        
        "#{target_model_name}_" 
      end
  
      protected
      def build(definition)
        definition.validates_with(target_model, model)
        @_key = definition[:_key]
        @custom_prefix = definition[:definition][:prefix]
        @custom_prefix = @custom_prefix.to_s unless @custom_prefix.nil?
       
        raise definition.error_message unless definition.valid?     
        self
      end
 
      def custom_prefix
        @custom_prefix
      end
 
      def _key
        @_key
      end
       
      # target helpers
      def target_model_name
        @target_model
      end

      def target_columns
        target_model.columns
      end

      def inspect
        # this prevents irb/console to inspect
        # circular references on big tree caused problem on #inspect 
      end

      private
      def is_parent_root?
        parent.present? && parent.instance_of?(RootNode)
      end
    end
  end
end
