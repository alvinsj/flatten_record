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
        parent.prefix + @column.name.to_s  
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
