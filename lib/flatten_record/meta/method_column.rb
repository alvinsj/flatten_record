module FlattenRecord
  module Meta
    class MethodColumn < Column
      def initialize(parent, method, target_model, model)
        @column = new_column(method, false, :integer, false)  
        super(parent, @column, target_model, model) 
      end

      private
      def new_column(col_name, col_default, col_type, not_null)
        ActiveRecord::ConnectionAdapters::Column.new(col_name, col_default, col_type, not_null)
      end
    end
  end
end
