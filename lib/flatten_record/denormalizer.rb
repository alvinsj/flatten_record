module FlattenRecord
  class Denormalizer
    def initialize(denormalizer_meta, normal_instance, prefix=nil)
      @meta = denormalizer_meta
      @normal = normal_instance
      @prefix = prefix 
    end

    def denormalize_record(to_record=nil)
      to_record ||= @meta.denormalized_model.new
      to_record = assign_custom_attrs(to_record) if @meta.custom_fields.present?
      to_record = assign_attrs(to_record)
      to_record = assign_children(to_record) if @meta.children.present?
      to_record
    end

    private
    def assign_children(to_record)
      @meta.children.each do |col, child_meta|
        association = @normal.class.reflect_on_association(col)
        link = @normal.send(col)
        next if link.blank?

        if association.macro == :has_many
          puts ":has_many"
          to_record = link.map {|i| Denormalizer.new(child_meta, i).denormalize_record(to_record.dup) }
        elsif association.macro == :belongs_to
          puts ":belongs_to"
          to_record = Denormalizer.new(child_meta, link).denormalize_record(to_record)
        end
      end
      to_record
    end

    def assign_attrs(to_record) 
      @meta.base_columns.each do |attr|
        to_record = assign_attr(to_record, "#{prefix}#{attr.name}", @normal.send(attr.name))
      end
      to_record = assign_attr(to_record, "#{prefix}#{@meta.id_column.name}", @normal.send(:id))
      to_record
    end
 
    def assign_custom_attrs(to_record) 
      @meta.custom_fields.each do |field, type|
        to_record = assign_attr(to_record, "#{prefix}#{field}", @normal.send("_get_#{field}", @normal))
      end
      to_record
    end
    
    def prefix
      @prefix.nil? ? "#{@meta.prefix}#{@meta.model_sym.to_s}_" : @prefix
    end
    
    def assign_attr(to_record, attr, value)
      assign_method = "#{attr}="
      if to_record.instance_of?(Array)
        to_record.map{|r| r.send(assign_method, value); r}
      else
        to_record.send(assign_method, value)
        to_record
      end
    end
    
  end
end
