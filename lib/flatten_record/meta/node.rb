module FlattenRecord
  module Meta
    class Node
      attr_reader :parent, :target_model, :model

      def initialize(parent, target_model, model)
        @parent = parent
        @target_model = target_model.to_s.camelize.constantize
        @model = model
      end
    
      protected
      def build(definition)
        definition.validates_with(target_model, model)
        raise definition.error_message unless definition.valid?     
      end

      def prefix
        return @custom_prefix unless @custom_prefix.nil?

        is_parent_root? ? "" :"#{parent.prefix}#{target_model_name}_" 
      end

      private
      def target_model_name
        target_model.name.underscore 
      end

      def is_parent_root?
        parent.present? && parent.instance_of?(RootNode) 
      end

    end
  end
end
