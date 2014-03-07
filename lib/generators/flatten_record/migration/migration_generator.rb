require 'rails/generators/active_record'

module FlattenRecord
  module Generators
    # Migration generator that creates migration file from template
    class MigrationGenerator < ActiveRecord::Generators::Base
      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end
      
      argument :name, :description => 'path to model'

      def generate_files
        defined_classes.each do |class_name|
          klass = class_name.constantize
          @table_name = klass.table_name
          @class_name = @table_name.camelize
          @table_columns = klass.denormalizer_meta.denormalized_columns
          migration_template 'migration.erb', "db/migrate/create_table_#{@table_name}.rb"
        end
      end

      def defined_classes
        require "#{Rails.root}/#{name}"
        FlattenRecord::Denormalize::Meta.included_classes
      end
    end
  end
end
