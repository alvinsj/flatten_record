module FlattenRecord
  module Meta
    class IdColumn < Column
      def initialize(parent, primary_key, target_model, model)
        @column = primary_key
        super(parent, @column, target_model, model) 
      end

      def name
        column_name = super
        target_name = target_model.name.underscore
        is_parent_root? ?
          target_name + "_" + column_name : 
          column_prefix(column_name)
      end
     
    end
  end
end
