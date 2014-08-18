module FlattenRecord
  module Meta
    class Column < Node
      attr_reader :column

      def initialize(parent, col, target_model, model)
        super(parent, target_model, model)
        @column = Struct.
          new(:name, :default, :type, :null).
          new(col.name, col.default, col.type, col.null)
      end
      
      def name
        default_name = parent.prefix + @column.name.to_s   
        is_parent_root? ? default_name : column_prefix(default_name)
      end

      def column_prefix(default_name)
        col_prefix = parent._key.to_s
          
        if target_model.table_name.to_s == col_prefix ||
          target_model_name == col_prefix
          return default_name
        end

        default_prefix = @custom_prefix || parent.parent.prefix
        parent_key = parent._key.to_s + "_"
        model_prefix = target_model_name + "_"
        
        default_prefix + parent_key + model_prefix +  @column.name.to_s
      end

      def type
        @column.type
      end

      def denormalize(instance, to_record)
        return nullify(to_records) if instance.blank?

        if instance.respond_to?(@column.name)
          to_record = assign_value(to_record, name) do |record|
            instance.send(@column.name.to_sym)
          end
        else
          raise "#{@column.name} is not found in #{instance.inspect}"
        end
        to_record
      end

      def nullify(to_record)
        assign_value(to_record, name) do |record|
          nil
        end
      end

      protected 
      def assign_value(to_record, name, &block)
        if to_record.respond_to?(:each)
          to_record = to_record.collect do |record|
            value = yield(record)
            record.send("#{name}=", value)
            record
          end
        else
          to_record.send("#{name}=", yield(to_record))
        end
        to_record
      end
     
    end # /Column
  end # /Meta
end
