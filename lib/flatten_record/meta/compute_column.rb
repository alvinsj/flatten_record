module FlattenRecord
  module Meta
    class ComputeColumn < Column
      def initialize(parent, method, type, target_model, model, options={})
        @column = Struct.
          new(:name, :default, :type, :null). 
          new(method, options[:default], type, options[:null])  
        
        super(parent, @column, target_model, model) 
      end

      def denormalize(instance, to_record)
        assign_value(to_record, name) do |record|
          record.send("compute_#{@column.name}".to_sym, instance)
        end
      end 
    end
  end
end
