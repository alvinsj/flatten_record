module FlattenRecord
  module Meta
    class AssociatedAttr < NormalizedAttr
      def initialize(parent, association, model)
        super(parent, association.klass, model)
        @association = association
      end

      def denormalize(instance, to_record)
        normal_s = instance.send(@association.name) 
        return nullify(to_record) if normal_s.blank?

        if normal_s.respond_to?(:find_each)
          to_record = multiply_and_denormalize(normal_s, to_record)
        else
          to_record = denormalize_children(normal_s, to_record)
          to_record = DenormalizedSet.init(to_record)
        end
        to_record.flatten
      end

      def foreign_key
        @association.foreign_key
      end
      
      def update(normal, to_records)
        to_records = DenormalizedSet.init(to_records) 
        children.each do |child|
          to_records = child.kind_of?(NormalizedAttr) ?
              update_normalized_attr(child, normal, to_records) : 
              update_column(child, normal, to_records)
        end
        to_records
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
        new_records = DenormalizedSet.new
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

      def update_normalized_attr(attr_node, normal, to_records)
        to_records = DenormalizedSet.init(to_records)
        matches = to_records.find_match(normal, attr_node)
        matches.each do |record_set|
          normal_s = normal.send(@association.name) 
          to_records.merge( attr_node.update(normal_s, record_set) )
        end
        to_records
      end

      def update_column(column_node, normal_s, to_records)
        if normal_s.respond_to?(:each)
          normal_s.each do |normal|
            to_records.merge( update_column_with_normal(column_node, normal, to_records))
          end
          to_records
        else
          update_column_with_normal(column_node, normal_s, to_records)
        end
      end

      def update_column_with_normal(column_node, normal, to_records)
        normal_s = normal.send(@association.name) 
        if normal_s.respond_to?(:find_each)
          normal_s.each do |n|
            to_records = column_node.update(n, to_records)
          end
          to_records
        else
          column_node.update(normal_s, to_records)
        end
      end

    end
  end
end
