module FlattenRecord
  
  class Config
    cattr_accessor :included_models
  end

  module Flattener
    def self.included(base)
      base.extend ClassMethods

      Config.included_models ||= []
      Config.included_models << base.to_s

      base.class_eval do
        cattr_reader :root_node, :normal_model, :definition_hash
      end
    end

    module ClassMethods
      def denormalize(normal_model, definition_hash)
        self.class_variable_set("@@definition_hash", definition_hash)
        self.class_variable_set("@@normal_model", normal_model.to_s.camelize.constantize)
      end

      def flattener_meta
       
        node = self.class_variable_get(:@@root_node)
        if node.blank?
          definition = Definition.new(self.definition_hash)

          root_node = Meta::RootNode.new(self.normal_model, self)
          root_node.build(definition)
 
          node = self.class_variable_set("@@root_node", root_node)
        end
        node
      end

      def create_with(normal)
        if normal_model.eql?(normal.class)
          destroy_with(normal)
          records = flattener_meta.denormalize(normal.reload, self.new)
          records.respond_to?(:each) ? records.each(&:save) : records.save
          records
        else
          destroy_with(normal)
          find_normals(normal).each do |n|
            create_with(n)
          end
        end
      end
      alias_method :update_with, :create_with

      def destroy_with(normal)
        if normal_model.eql?(normal.class)
          records = find_with(normal)
          records.each(&:destroy)
        else
          # update associated model
          find_normals(normal).each do |n|
            update_with(n)
          end
        end
        records
      end

      def find_normals(normal)
        return normal if normal_model.eql?(normal.class)
        
        records = find_with(normal)
        id_name = flattener_meta.id_column.name
        normal_id_name = flattener_meta.id_column.column.name
        
        ids = records.collect{|c| c.send(id_name.to_sym) }
        normal_model.where(normal_id_name => ids)
      end

      def find_with(normal)
        node = find_node(:target_model, normal.class)
        
        raise "#{normal.class} was not defined in the denormalization" if node.nil?
        id_name = node.id_column.name 
        normal_id_name = node.id_column.column.name

        self.where(id_name => normal.send(normal_id_name))
      end

      def find_node(type, value)
        flattener_meta.traverse_by(type, value)
      end
    end # /ClassMethods

  end
end

