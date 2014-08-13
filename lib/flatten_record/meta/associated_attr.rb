module FlattenRecord
  module Meta
    class AssociatedAttr < NormalizedAttr
      def initialize(parent, association, model) 
        super(parent, association.klass, model)
        @association = association
      end

      def denormalize(instance, to_record)
        kid_s = instance.send(@association.name) 
        return to_record if kid_s.blank?

        if kid_s.respond_to?(:find_each)
          new_records = []
          kid_s.find_each do |kid|
            new_records << denormalize_children(kid, to_record.dup)
          end
          to_record = new_records.flatten
        else
          to_record = denormalize_children(kid_s, to_record)
        end

        to_record
      end

      def foreign_key
        @association.foreign_key
      end
     
      private
      def denormalize_children(instance, to_record)
        children.each do |child|
          to_record = child.denormalize(instance, to_record)
        end
        to_record
      end

      protected
      attr_reader :association

      def options
        association.options
      end
    end
  end
end
