module FlattenRecord

  module Flattener
    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        cattr_accessor :flat_meta
      end
    end

    module ClassMethods
      def denormalize(target_model, definition_hash)
        definition = Definition.new(definition_hash)

        meta_node = Meta::RootNode.new(target_model, self)
        meta_node.build(definition)

        self.flat_meta = OpenStruct.new(root: meta_node)
      end

      def create_denormalized(normal)
        flat_meta.root.denormalize(normal)
      end

      def destroy_denormalized(normal)
        flat_meta.root.destroy(normal)
      end
    end # /ClassMethods
    
  end
end
