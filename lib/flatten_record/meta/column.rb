module FlattenRecord
  module Meta
    class Column < Node
      def initialize(parent, col, target_model, model)
        super(parent, target_model, model)
        @column = col
      end
      
      def name
        parent.prefix + @column.name.to_s
      end

      def denormalize(instance, to_record)
        if instance.respond_to?(@column.name)
          assign_value(to_record, name) do |record|
            instance.send(@column.name.to_sym)
          end
        else
          raise "#{@column.name} is not found in #{instance.inspect}"
        end
        to_record
      end

      protected 
      
      def assign_value(to_record, name, &block)
        if to_record.respond_to?(:each)
          to_record.each do |record|
            value = yield(record)
            record.send("#{name}=", value)
          end
        else
          to_record.send("#{name}=", yield(to_record))
        end
      end
      
    end # /Column
  end # /Meta
end
