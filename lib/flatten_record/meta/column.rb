module FlattenRecord
  module Meta
    class Column < Node
      def initialize(parent, col, target_model, model)
        super(parent, target_model, model)
        @col = col
      end
      
      def name
        prefix + @col.name.to_s
      end
    end # /Column
  end # /Meta
end
