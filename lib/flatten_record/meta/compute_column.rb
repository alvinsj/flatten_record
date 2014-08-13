module FlattenRecord
  module Meta
    class ComputeColumn < Column
      def initialize(parent, method, target_model, model)
        @column = new_column(method, false, :integer, false)  
        super(parent, @column, target_model, model) 
      end

      def denormalize(instance, to_record)
        if to_record.respond_to?(@column.name)
          to_record = assign_value(to_record, name) do |record|
            record.send(@column.name.to_sym)
          end
        else
          raise "#{@column.name} is not found in #{to_record.inspect}"
        end
        to_record
      end
     
      private
      def new_column(col_name, col_default, col_type, not_null)
        ActiveRecord::ConnectionAdapters::Column.new(col_name, col_default, col_type, not_null)
      end
    end
  end
end
