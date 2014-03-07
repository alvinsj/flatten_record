module FlattenRecord

  class AttrDenormalizer
    def initialize(denormalizer_meta, col)
      @denormalizer_meta = denormalizer_meta
      @attr_name = attr_name
      @options = options
    end

    def denormalize_record(normal_record, base_record)
      raise "no denormalize method found in attr denormalizer" 
    end

    def denormalized_model
      @denormalizer_meta.denormalized_model
    end 
  end
  
  class BelongsToAttrDenormalizer < AttrDenormalizer
    def denormalize_record(normal_instance, base_record)
      belongs_to = normal_instance.send(@attr_name.to_sym)
      if belongs_to.present?
        base_record = denormalize_child_attrs(belongs_to)
      end
    end 

    def denormalize_child_attrs(belongs_to)
      belongs_to.class.columns.each do |column|
        denormalized_instace = denormalized_model.new
        denormalized_instance.send(
          @denormalizer_meta.prefix + column.name + '=', 
          belongs_to.send(column.name.to_sym))
      end 
    end
    
  end

  class HasManyAttrDenormalizer < AttrDenormalizer
    def denormalize(normal_instance, base_record)
      has_many = from_instance.send(@attr_name.to_sym)
      if !has_many.blank?
        has_many.each do |child|
          denormalized_instance = denormalized_model.new
          child.class.columns.each do |column|
            denormalized_instance.send(@denormalizer_meta.prefix + column.name + '=', 
                       child.send(column.name.to_sym))
          end
        end 
      end
   end
  end
end
