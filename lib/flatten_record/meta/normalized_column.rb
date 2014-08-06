module FlattenRecord
  module Meta
    class NormalizedColumn < Node
      def child_models
        @children.map(&:child_models).flatten
      end
      
      def columns
        child_columns = @children.values.map{|c| c[:columns] + c[:methods] }.flatten
        @columns + @methods + child_columns 
      end

      def [](key)
        instance_variable_get "@#{key}"
      end

      protected
      def build(definition)
        super(definition)

        @columns = build_columns(definition) || []
        @methods = build_methods(definition) || []
        @children = build_children(definition) || {}
      end

      private
      def build_columns(definition)
        cols = target_model.columns.select{|col| !col.primary }
        if definition[:only].present?
          cols = cols.select{|col| definition[:only].include?(col.name.to_sym) }
        elsif definition[:except].present?
          cols = cols.select{|col| !definition[:except].include?(col.name.to_sym) }
        end
        cols.map{|col| Column.new(self, col, target_model, model)}
      end 

      def build_methods(definition)
        return [] unless definition[:methods] 
        
        definition[:methods].map do |method| 
          CustomColumn.new(self, method, target_model, model)
        end
      end

      def build_children(definition)
        return {} unless definition[:include]
        children = Hash.new
        definition[:include].each do |child, child_definition|
          children[child] = node_factory(self, child)
          children[child].build(child_definition)
        end
        children
      end

      def node_factory(parent, child)
        klass_map = [:has_many, :belongs_to, :has_one]

        association = target_model.reflect_on_association(child)
        node = nil
        
        if klass_map.include?(association.macro)
          klass = association.macro.to_s.camelize.to_sym
          node = Meta.const_get(klass).new(parent, association, association.klass, model)
        elsif associaton.macro.nil?
          raise "association with '#{child}' on #{target_model.name.underscore} is not found"
        else
          raise "association type '#{association.macro}' with '#{child}' is not supported"
        end
        node 
      end

    end #/NormalizedColumn
  end
end
