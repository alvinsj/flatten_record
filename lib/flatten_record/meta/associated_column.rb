module FlattenRecord
  module Meta
    class AssociatedColumn < NormalizedColumn
      def initialize(parent, association, model) 
        super(parent, association.klass, model)
        @association = association
      end

      def denormalize(instance, to_record)
        kid_s = instance.send(@association.name.to_s) 
         
        if kid_s.present? && kid_s.respond_to?(:count)
          kid_s.map do |kid|
            puts kid.inspect
            denormalize_children(kid, to_record.dup)
          end.flatten
        elsif kid_s.present?
          denormalize_children(kid_s, to_record)
        end
      end

      def foreign_key
        @association.foreign_key
      end
     
      private
      def denormalize_children(instance, to_record)
        children.map do |child|
          child.denormalize(instance, to_record)
        end.flatten
      end

      protected
      attr_reader :association

      def options
        association.options
      end
    end
  end
end
