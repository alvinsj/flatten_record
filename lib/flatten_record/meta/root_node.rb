module FlattenRecord
  module Meta
    class RootNode < NormalizedAttr
      def initialize(target_model, model)
        super(nil, target_model, model)
      end
      
      def build(definition)
        super(definition)
      end

      def prefix
        ""
      end
    end
  end
end
