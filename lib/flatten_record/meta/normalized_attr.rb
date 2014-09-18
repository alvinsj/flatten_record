module FlattenRecord
  module Meta
    class NormalizedAttr < Node
      
      def denormalize(instance, to_record)
        denormalize_children(instance, to_record)
      end
      
      def all_columns
        child_columns = @include.values.collect(&:all_columns)
        @base_columns + @methods + @compute + child_columns.flatten 
      end

      def associated_models
        @include.blank? ? target_model : @include.values.collect(&:associated_models).flatten
      end

      def [](key)
        instance_variable_get("@#{key}") 
      end
      
      def prefix
        custom_prefix || "#{parent.prefix}#{target_model_name}_"
      end

      def traverse_by(attr, value)
        attr_value = send("#{attr}")

        if !value.respond_to?(:to_s) || !attr_value.respond_to?(:to_s)
          raise "traverse error: to_s method required for comparison"
        end
        
        if value.to_s.downcase == attr_value.to_s.downcase
          return self
        else
          found = nil
          @include.values.each do |node|
            n = node.traverse_by(attr, value)
            found = n unless n.nil?
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
        super(definition)
        
        @foreign_keys = []
        primary_key = target_columns.select(&:primary).first
        @id_column = IdColumn.new(self, primary_key, target_model, model)
        
        @compute = build_compute(definition) || []
        @methods = build_methods(definition) || []
        @include = build_children(definition) || {}
        @base_columns = build_columns(definition) || []
        
        validate_columns(all_columns)

        self
      end

      def validate_columns(columns)
        dups = find_dup_columns(columns)
        if dups.present?
          raise "Duplicate columns found: #{dups.join(", ")}"
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
            type = options[:type]
          end

          ComputeColumn.
            new(self, method, type, target_model, model, options).
            build(definition)
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

          MethodColumn.
            new(self, method, type, target_model, model).
            build(definition)
        end
      end

      def build_children(definition)
        return {} unless definition[:include]
        
        children = {}
        definition[:include].each do |child, child_definition|
          class_name = child_definition[:definition][:class_name]
          children[child] = associated_node_factory(self, child, class_name)
          children[child].build(child_definition)
        end
        children
      end

      private
      def find_dup_columns(columns)
        dups = []
        columns.each do |column|
          if match_columns?(columns, column)
            parent_target = column.parent.target_model
            original_name = column.column.name
            dups << "#{column.name} was from #{parent_target}'s #{original_name}"
          end
        end
        dups
      end

      def match_columns?(columns, column)
        columns.each do |c|
          if c.parent != column.parent && c.name == column.name
            return true
          end
        end
        false
      end

      def associated_node_factory(parent, child, class_name)
        association = target_model.reflect_on_association(child)

        raise_missing_macro(child, target_model) unless association.macro
        
        if association_node?(association.macro)
          class_name ||= association.klass
          type = "#{association.macro}"
          klass = Meta.const_get(type.camelize)
          
          @foreign_keys << association.foreign_key.to_s 
          klass.new(parent, association, class_name, model)
        else
          raise_unsupported_type(association.macro, target_model)
        end
      end

      def association_node?(type)
        [:has_many, :belongs_to, :has_one].include?(type) 
      end

      def raise_unsupported_type(type, model)
        raise "association type '#{type}' with '#{model}' is not supported"
      end

      def raise_missing_macro(child, model)
        raise "association with '#{child}' on #{model} is not found"
      end

      def columns_from_definition(definition)
        target_columns.
          select {|col| allow_column?(col, definition) }.
          map do |col| 
            Column.
              new(self, col, target_model, model).
              build(definition)
          end
      end

      def allow_column?(col, definition)
        return false if col.primary
        return false if @foreign_keys.include?(col.name.to_s) 

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
