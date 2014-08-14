module FlattenRecord
  module Meta
    class AssociatedAttr < NormalizedAttr
      def initialize(parent, association, association_klass, model)
        super(parent, association_klass, model)
        @association = association
      end

      def denormalize(instance, to_record)
        normal_s = instance.send(@association.name) 
        return nullify(to_record) if normal_s.blank?

        if normal_s.respond_to?(:find_each)
          to_record = multiply_and_denormalize(normal_s, to_record)
        else
          to_record = denormalize_children(normal_s, to_record)
          to_record = [to_record]
        end
        to_record.flatten
      end

      def foreign_key
        @association.foreign_key
      end
     
      def nullify(to_record)
        children.each do |child|
          child.nullify(to_record)
        end
        to_record
      end
      
      protected
      attr_reader :association

      def options
        association.options
      end
    
      private
      def multiply_and_denormalize(records, to_record)
        new_records = []
        index = 0
        records.find_each do |record|
          new_records << (
            index == 0 ?
              denormalize_children(record, to_record) :
              denormalize_children(record, to_record.dup) 
          )
          index += 1
        end
        new_records
      end

    end
  end
end
