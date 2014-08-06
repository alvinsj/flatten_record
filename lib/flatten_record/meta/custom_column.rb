module FlattenRecord
  module Meta
    class CustomColumn < Column
      def initialize(parent, method, target_model, model)
        col = new_column(method, false, :integer, false)  
        super(parent, col, target_model, model) 
      end

      def new_column(col_name, col_default, col_type, not_null)
        ActiveRecord::ConnectionAdapters::Column.new(col_name, col_default, col_type, not_null)
      end

    end
  end
end
