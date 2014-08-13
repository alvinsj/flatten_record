module FlattenRecord

  module Flattener
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        cattr_accessor :flat_meta, :normal_model
      end
    end

    module ClassMethods
      def denormalize(normal_model, definition_hash)
        definition = Definition.new(definition_hash)

        root_node = Meta::RootNode.new(normal_model, self)
        root_node.build(definition)

        self.flat_meta = Struct.new(:root_node).new(root_node)
        self.normal_model = flat_meta.root_node.target_model
      end

      def create_with(normal)
        raise "unmatch model type #{normal.class.inspect}" unless normal_model.eql?(normal.class)
        records = flat_meta.root_node.denormalize(normal, self.new)
        records.each(&:save)
        records
      end

      def update_with(normal)
        records = find_with(normal)
        records.find_each{|record| record.update_with(normal)}
        records
      end

      def destroy_with(normal)
        records = find_with(normal)
        if normal_model.eql?(normal.class)
          records.find_each{|r| r.destroy }
        else
          records.find_each{|r| r.update_with(normal) }
        end
        records
      end

      def find_with(normal)
        node = flat_meta.root_node.traverse_by(:target_model, normal.class)

        id_name = node.id_column.name 
        normal_id_name = node.id_column.column.name

        self.where(id_name, normal.send(normal_id_name))
      end
    end # /ClassMethods

    def update_with(normal)
      node = self.class.flat_meta.root_node.traverse_by(:target_model, normal.class)
      records = node.update(normal, self)
      records.each(&:save)
      records
    end
  end
end
