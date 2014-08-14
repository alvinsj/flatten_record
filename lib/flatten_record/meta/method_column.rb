module FlattenRecord
  module Meta
    class MethodColumn < Column
      def initialize(parent, method, type, target_model, model, options={})
        @column = new_column(method, options[:default], type, options[:not_null])  
        super(parent, @column, target_model, model) 
      end

      private
      def new_column(col_name, col_default, col_type, not_null)
        ActiveRecord::ConnectionAdapters::Column.new(col_name, col_default, col_type, not_null)
      end
    end
  end
end
