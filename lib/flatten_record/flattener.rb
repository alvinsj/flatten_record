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

        self.flat_meta = Struct.new(:root).new(meta_node)
      end

      def create_with(normal)
        records = flat_meta.root.denormalize(normal, self.new)
        records.each(&:save)
        records
      end

    end # /ClassMethods
    
  end
end
