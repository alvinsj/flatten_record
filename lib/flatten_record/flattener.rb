module FlattenRecord

  module Flattener
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        cattr_accessor :flattener_meta, :normal_model
      end
    end

    module ClassMethods
      def denormalize(normal_model, definition_hash)
        definition = Definition.new(definition_hash)

        root_node = Meta::RootNode.new(normal_model, self)
        root_node.build(definition)

        self.flattener_meta = root_node
        self.normal_model = root_node.target_model
      end

      def create_with(normal)
        raise "unmatch model type #{normal.class.inspect}" unless normal_model.eql?(normal.class)
        records = flattener_meta.denormalize(normal, self.new)
        records.each(&:save)
        records
      end

      def update_with(normal)
       
        if normal.class.eql?(normal_model)
          records = find_with(normal)
          flattener_meta.update(normal, records)
        
        else 
          node = find_node(:target_model, normal.class)
          id_column = node.id_column
          
          records = find_with(normal)
          ids = records.map(&(id_column.name.to_sym))
          
          normals = normal_model.where(id_column.column.name => ids)
          
          normals.collect do |n|
            flattener_meta.update(n, records)
          end
        end.flatten
      end

      def destroy_with(normal)
        records = find_with(normal)
        if normal_model.eql?(normal.class)
          records.each{|r| r.destroy }
        else
          self.update(normal, records) 
        end
        records
      end

      def find_with(normal)
        node = find_node(:target_model, normal.class)

        id_name = node.id_column.name 
        normal_id_name = node.id_column.column.name

        DenormalizedSet.init(self.where(id_name, normal.send(normal_id_name)))
      end

      def find_node(type, value)
        flattener_meta.traverse_by(type, value)
      end
    end # /ClassMethods

  end
end

