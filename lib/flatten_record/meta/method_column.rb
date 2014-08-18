module FlattenRecord
  module Meta
    class MethodColumn < Column
      def initialize(parent, method, type, target_model, model, options={})
        @column = Struct.
          new(:name, :default, :type, :null).
          new(method, options[:default], type, options[:null])

        super(parent, @column, target_model, model) 
      end
    end
  end
end
