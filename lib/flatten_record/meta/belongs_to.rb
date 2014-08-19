module FlattenRecord
  module Meta
    class BelongsTo < AssociatedAttr
      def prefix
        if options[:polymorphic]
          custom_prefix || 
            "#{parent.prefix}#{_key.to_s}_#{target_model_name}_" 
        else
          super
        end
      end

    end
  end
end
