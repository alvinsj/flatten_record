module FlattenRecord
  class DenormalizerMeta

    attr_reader :target, :options, :denormalized_model  
    delegate :model, :denormalized_model, :columns, to: :target, prefix: true
    delegate :child_metas, :denormalized_columns, :id_column, :columns_prefix, :custom_fields, to: :target

    def initialize(model_sym, denormalized_model, options={})
      @options = options
      @target = Target.new(model_sym, denormalized_model, options)

      #model_sym = options[:as] if options[:as]
      
      @is_root = options[:is_root]
    end
    
    # called by denormalizer block 
    def denormalize(field, field_options={}, &block)
      association = target.model.reflect_on_association(field)
      raise "Invalid association #{field}" if association.nil?

      associated_model = field_options[:as].present? ? 
          field_options[:as].to_s.camelize.constantize : 
          association.class_name.camelize.constantize
      
      target.field_options[field] = field_options
      child_prefix = "#{target.columns_prefix}#{field.to_s}_" 
      
      target.child_metas[field] = 
        DenormalizerMeta.new(field, target.denormalized_model, field_options.merge(prefix: child_prefix) )
          
      if block 
        yield target.child_metas[field]
      end 
    end

    def save(col_name, col_type, extras={})
      target.custom_columns << ActiveRecord::ConnectionAdapters::
          Column.new(col_name.to_s, extras[:default], col_type, extras[:null])
    end

    class Target
      attr_accessor :custom_columns, :child_metas, :field_options
      attr_reader :denormalized_model, :sym, :options

      def initialize(target_model_sym, denormalized_model, options={})
        @sym = options[:as] ? options[:as] : target_model_sym
        @denormalized_model = denormalized_model
        @options = options
      end

      def model
        @model ||= @sym.to_s.singularize.camelize.constantize
      end

      def field_options
        @field_options ||= {}
      end

      def child_metas
        @child_metas ||= {}
      end

      def custom_columns
        @custom_columns ||= []
      end

      def columns
        return @columns unless @columns.blank?

        @columns = model.columns.select{|col| col.name!='id' }
        if options[:only]
          @columns = @columns.select{|col| options[:only].include?(col.name.to_sym) }
        elsif options[:except]
          @columns = @columns.select{|col| !options[:except].include?(col.name.to_sym) }
        end
        @columns
      end

      def custom_fields
        cols = custom_columns.map{|col| [col.name, col.type]}
        Hash[*(cols.flatten)]
      end

      def id_column
        @id_column ||= ActiveRecord::ConnectionAdapters::
          Column.new(id_column_name, nil, :integer, true )
      end

      def columns_prefix
        "#{options[:prefix]}"
      end
   
      def denormalized_columns
        prefix_columns(columns_prefix, [id_column] + columns + custom_columns) + child_denormalizers_columns
      end 

      private
      def prefix_columns(namespace, all_columns)
        return all_columns if options[:is_root]
        all_columns.
          map do |col| 
            col_name = "#{namespace}#{col.name}"; col
            ActiveRecord::ConnectionAdapters::Column.
              new(col_name, col.default, col.sql_type, col.null)
          end
      end

      def id_column_name
        model.table_name.singularize + "_id"
      end

      def child_denormalizers_columns
        child_metas.map{|k,v| v.denormalized_columns }.flatten
      end
    end

  end
end
