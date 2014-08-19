module FlattenRecord
  module Meta
    class IdColumn < Column
      def initialize(parent, primary_key, target_model, model)
        @column = primary_key
        super(parent, @column, target_model, model) 
      end

      def name
        column_name = super
        is_parent_root? ?
          target_model_name + "_" + column_name : 
          column_name
      end
     
    end
  end
end
