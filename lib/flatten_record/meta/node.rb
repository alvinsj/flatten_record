module FlattenRecord
  module Meta
    class Node
      attr_reader :parent, :children, :target_model, :model, :denormalized, :pending

      def initialize(parent, target_model, model)
        @parent = parent
        @target_model = target_model.is_a?(ActiveRecord::Base) ? 
          target_model : target_model.to_s.camelize.constantize
        @model = model
      end

      def traverse_by(attr, value)
        attr_value = instance_variable_get("@#{attr}")

        if !value.respond_to?(:to_s) || !attr_value.respond_to?(:to_s)
          raise "traverse error: to_s method required for comparison"
        end
 
        if value.to_s == attr_value.to_s
          return self
        else 
          return nil
        end
      end
 
      def prefix
        return @custom_prefix unless @custom_prefix.nil?
        is_parent_root? ? "" : "#{target_model_name}_" 
      end
    
      protected
      def build(definition)
        definition.validates_with(target_model, model)
        raise definition.error_message unless definition.valid?     
      end
       
      # target helpers
      def target_model_name
        target_model.name.underscore 
      end

      def target_columns
        target_model.columns
      end

      private
      def is_parent_root?
        parent.present? && parent.instance_of?(RootNode)
      end
    end
  end
end
