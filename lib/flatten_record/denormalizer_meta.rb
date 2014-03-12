module FlattenRecord
  class DenormalizerMeta

    def initialize(model_sym, denormalized_model_class, options={})
      @model_sym = model_sym 
      model_sym = options[:as] if options[:as]
      
      @normal_model = model_sym.to_s.singularize.camelize.constantize
      @denormalized_model = denormalized_model_class
      @options = options || Hash.new
      
      @columns = @normal_model.columns.select{|col| col.name!='id' }
      if options[:only]
        @columns = @columns.select{|col| options[:only].include?(col.name.to_sym) }
      elsif options[:except]
        @columns = @columns.select{|col| !options[:except].include?(col.name.to_sym) }
      end

      @extra_columns = Array.new
      
      @child_denormalizer_metas = Hash.new
      @options_for_child = Hash.new
      
      @attr_denormalizers = Array.new
      @custom_fields = Hash.new
      @is_root = options[:is_root]
    end
    
    # calleb by denormalizer block 
    def denormalize(field, field_options={}, &block)

      association = @normal_model.reflect_on_association(field)
      raise "Invalid association #{field}" if association.nil?

      associated_model = field_options[:as].present? ? 
          field_options[:as].to_s.camelize.constantize : 
          association.class_name.constantize
      
      @options_for_child[field] = field_options
      child_prefix = "#{prefix}#{field.to_s}_" 
      
      @child_denormalizer_metas[field] = 
        DenormalizerMeta.new(field, @denormalized_model, field_options.merge(prefix: child_prefix) )
          
      if block 
        yield @child_denormalizer_metas[field]
      end 
    end

    def save(col_name, col_type, extras={})
      @extra_columns << ActiveRecord::ConnectionAdapters::
          Column.new(col_name.to_s, extras[:default], col_type, extras[:null])
      @custom_fields[col_name] = col_type
    end
    
    #
    # read only properties
    #
    def normal_model
      @normal_model
    end
  
    def model_sym
      @model_sym
    end

    def denormalized_model
      @denormalized_model
    end

    def denormalized_columns
      prefix_columns(prefix, [id_column] + @columns + @extra_columns) + child_denormalizers_columns
    end

    def base_columns
      @columns
    end

    def extra_columns
      @extra_columns
    end
 
    def id_column
      @id_column ||= ActiveRecord::ConnectionAdapters::
          Column.new(id_column_name, nil, :integer, true )
    end
    
    def options_for_child(child)
      @options_for_child[child]
    end

    def options
      @options
    end

    def prefix
      "#{@options[:prefix]}"
    end
    
    def children
      @child_denormalizer_metas
    end

    def custom_fields
      @custom_fields
    end

    #
    # private methods
    # 
    private 
    def id_column_name
      @normal_model.table_name.singularize + "_id"
    end

    def child_denormalizers_columns
      @child_denormalizer_metas.map{|k,v| v.denormalized_columns }.flatten
    end
    
    def prefix_columns(namespace, columns)
      return columns if @is_root
      columns.
        map do |col| 
          col_name = "#{namespace}#{col.name}"; col
          ActiveRecord::ConnectionAdapters::Column.
            new(col_name, col.default, col.sql_type, col.null)
        end
    end
  end
end
