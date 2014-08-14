module FlattenRecord
  module Meta
    class NormalizedAttr < Node
      
      def denormalize(instance, to_record)
        denormalize_children(instance, to_record)
      end
      
      def all_columns
        return @columns if @columns
        child_columns = @include.values.map do |c|
          c[:columns] + c[:methods] + c[:compute]
        end
        child_columns.flatten!
        @columns = @base_columns + @methods + @compute + child_columns 
      end

      def [](key)
        instance_variable_get("@#{key}") 
      end
      
      def prefix
        @custom_prefix || parent.prefix+target_model.name.underscore.to_s + "_"
      end

      def traverse_by(attr, value)
        attr_value = instance_variable_get("@#{attr}")

        if !value.respond_to?(:to_s) || !attr_value.respond_to?(:to_s)
          raise "traverse error: to_s method required for comparison"
        end
        
        if value.to_s == attr_value.to_s
          return self
        else
          found = nil
          @include.values.each do |node|
            found = node.traverse_by(attr, value)
          end 
          return found
        end
      end

      def id_column
        return @id_column unless @id_column.nil?
      end

      protected
      def denormalize_children(instance, to_record)
        children.each do |child|
          to_record = child.denormalize(instance, to_record)
        end
        to_record
      end

      def build(definition)
        definition = super(definition)

        primary_key = target_columns.select(&:primary).first
        @id_column = IdColumn.new(self, primary_key, target_model, model)

        @excluded_columns = []
        @compute = build_compute(definition) || []
        @methods = build_methods(definition) || []
        @include = build_children(definition) || {}
        @base_columns = build_columns(definition) || []
        
        dups = find_dup_columns
        if !dups.blank?
          raise "#{@excluded_columns.inspect}Duplicate columns found: #{dups.join(", ")}"
        end
      end
      
      def children
        (@base_columns + @compute + @methods + @include.values)
      end

      def build_columns(definition)
        cols = columns_from_definition(definition)
        [id_column] + cols 
      end 

      def build_compute(definition)
        return [] unless definition[:compute] 
        
        definition[:compute].map do |method, type| 
          options = {}
          if type.is_a?(Hash)
            options = type
            type = options[:sql_type]
          end

          ComputeColumn.new(self, method, type, target_model, model, options)
        end
      end

      def build_methods(definition)
        return [] unless definition[:methods] 
        
        definition[:methods].map do |method, type|
          options = {}
          if type.is_a?(Hash)
            options = type
            type = options[:sql_type]
          end

          MethodColumn.new(self, method, type, target_model, model)
        end
      end

      def build_children(definition)
        return {} unless definition[:include]
        children = Hash.new
        definition[:include].each do |child, child_definition|
          children[child] = node_factory(self, child, child_definition[:definition][:class_name])
          children[child].build(child_definition)
        end
        children
      end

      private
      def find_dup_columns
        dups = []
        all_columns.each do |column|
          all_columns.each do |comp|
            if comp.parent != column.parent && comp.name == column.name
              parent_target = column.parent.target_model.to_s
              original_name = column.column.name
              dups << "#{column.name} was from #{parent_target}'s #{original_name}"
            end
          end
        end
        dups
      end

      def node_factory(parent, child, class_name)
        klass_map = [:has_many, :belongs_to, :has_one]

        association = target_model.reflect_on_association(child)
        @excluded_columns << association.foreign_key.to_s
        
        class_name ||= association.klass
        node = nil
        
        if klass_map.include?(association.macro)
          klass = association.macro.to_s.camelize.to_sym
          node = Meta.const_get(klass).new(parent, association, class_name, model)
        elsif associaton.macro.nil?
          raise "association with '#{child}' on #{target_model.name.underscore} is not found"
        else
          raise "association type '#{association.macro}' with '#{child}' is not supported"
        end
        node 
      end

      def columns_from_definition(definition)
        target_columns.
          select {|col| allow_column?(col, definition) }.
          map {|col| Column.new(self, col, target_model, model)} 
      end

      def allow_column?(col, definition)
        return false if col.primary
        return false if @excluded_columns.include?(col.name.to_s) 

        if definition[:only].present?
          definition[:only].include?(col.name.to_sym) 
        elsif definition[:except].present?
          !definition[:except].include?(col.name.to_sym) 
        else
          true
        end
      end

    end #/NormalizedAttr
  end
end
