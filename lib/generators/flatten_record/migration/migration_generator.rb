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
        return puts("Error. #{name.camelize} is not found") unless valid?
        defined_classes.each do |class_name|
          klass = class_name.constantize
          @table_name = klass.table_name
          @class_name = @table_name.camelize
          if klass.table_exists?
            puts "Error. Table already exists: #{@table_name}"
          elsif klass.denormalizer_meta
            @table_columns = klass.denormalizer_meta.denormalized_columns
            migration_template 'migration.erb', "db/migrate/create_table_#{@table_name}.rb"
          else
            puts "Error. No denormalization definition found in #{class_name}"
          end
        end
      end

      def defined_classes
        klass = name.camelize
        [klass]
      end

      def valid?
        Rails.application.eager_load!
        klass = name.camelize
        klasses = FlattenRecord::Denormalize::Meta.included_classes
        klasses.include?(klass)
      end
    end
  end
end
