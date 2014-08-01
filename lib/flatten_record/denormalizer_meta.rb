module FlattenRecord
  class DenormalizerMeta

    attr_reader :target_model, :model, :options, 
                :child_metas, :custom_columns, :field_options

    def initialize(target_model_sym, model, options={}) 
      sym = options[:as] ? options[:as] : target_model_sym
      
      @target_model = sym.to_s.singularize.camelize.constantize
      @model = model
      @options = options
      
      @custom_columns = []
      @child_metas = @field_options = {}
    end

    #
    # main methods 
    #
    def denormalize(field, field_options={}, &block)
      meta = denormalize_field(field, field_options)
      yield meta if block
    end
    
    def save(col_name, col_type, extras={})
      add_custom_column(col_name, col_type, extras)
    end
    
    # 
    # properties
    #
    def custom_fields
      cols = custom_columns.map{|col| [col.name, col.type]}
      Hash[*(cols.flatten)]
    end

    def id_column
      @id_column ||= new_column(id_column_name, nil, :integer, true )
    end

    def columns_prefix
      "#{options[:prefix]}"
    end
 
    def denormalized_columns
      @denomalized_columns ||= 
        prefix_columns(columns_prefix, all_columns) + child_columns
    end 
 
    def target_columns
      return @columns unless @columns.blank?

      @columns = target_model.columns.select{|col| col.name!='id' }
      if options[:only]
        @columns = @columns.select{|col| options[:only].include?(col.name.to_sym) }
      elsif options[:except]
        @columns = @columns.select{|col| !options[:except].include?(col.name.to_sym) }
      end
      @columns
    end

    private
    def denormalize_field(field, field_options={})
      # enforce association information
      raise "Invalid association #{field}" if associated_with?(field)
       
      opts = field_options.merge(prefix: field_prefix(field)) 
      @child_metas[field] = DenormalizerMeta.new(field, target_model, opts)
    end

    def add_custom_column(col_name, col_type, extras={})       
      @custom_columns << 
        new_column(col_name.to_s, extras[:default], col_type, extras[:null])
    end

    def prefix_columns(namespace, all_columns)
      return all_columns if options[:is_root]
      all_columns.map do |col| 
        col_name = "#{namespace}#{col.name}"; col
        new_column(col_name, col.default, col.sql_type, col.null)
      end
    end

    def new_column(col_name, col_default, col_type, not_null)
      ActiveRecord::ConnectionAdapters::Column.new(col_name, col_default, col_type, not_null)
    end

    #
    # quick method
    #
    def associated_with?(field) 
      target_model.reflect_on_association(field).nil?
    end

    def id_column_name
      target_model.table_name.singularize + "_id"
    end
   
    def all_columns
      [id_column] + target_columns + custom_columns 
    end

    def child_columns
      child_metas.map{|k,v| v.denormalized_columns }.flatten
    end

    def field_prefix(field)
      "#{columns_prefix}#{field.to_s}_" 
    end

  end
end
