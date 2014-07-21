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
        unless valid? 
          puts("Error. #{name.camelize} is not found") and return
        end

        defined_classes.each do |class_name|
          @klass = class_name.constantize
          @table_name = @klass.table_name
          @table_columns = denormalized_columns if @klass.denormalizer_meta

          case
          when @klass.table_exists?
            puts("Warning. Table already exists: #{@table_name}")
            diff_and_generate if @klass.denormalizer_meta 
          
          when @klass.denormalizer_meta
            migration_template('migration.erb', "db/migrate/create_table_#{@table_name}.rb")
          
          else
            puts("Error. No denormalization definition found in #{class_name}")
          end
        end
      end

      private
      def denormalized_columns
        @klass.denormalizer_meta.denormalized_columns
      end
      
      def diff_and_generate
        if any_diff?
          puts "Generating migration based on the difference.."
          puts "Add columns: #{add_columns_names}" unless add_columns.empty?
          puts "Drop columns: #{drop_columns_names}" unless drop_columns.empty?

          @migration = add_columns.empty? ? 
            "drop_#{drop_columns.first.name}_from" : 
            "add_#{add_columns.first.name}_to"
          
          migration_template('update.erb', "db/migrate/#{@migration}_#{@table_name}.rb")
        end
      end

      def any_diff?
        !add_columns.empty? || !drop_columns.empty? 
      end

      def add_columns_names
        add_columns.collect(&:name).join(', ')
      end

      def drop_columns_names
        drop_columns.collect(&:name).join(', ')
      end

      def add_columns
        @add_columns ||= denormalized_columns.inject([]) do |cols, col| 
          cols ||= []
          @klass.columns.collect(&:name).include?(col.name) ?
            cols : cols << col
        end
      end
      
      def drop_columns
        @drop_columns ||= @klass.columns.inject([]) do |cols, col|
          next if col.name == 'id'
          cols ||= []
          denormalized_columns.collect(&:name).include?(col.name) ?
            cols : cols << col
        end
      end

      def denormalized_columns
        @klass.denormalizer_meta.denormalized_columns
      end

      def defined_classes
        @klass = name.camelize
        [@klass]
      end

      def valid?
        Rails.application.eager_load!
        @klass = name.camelize
        @klasses = FlattenRecord::Denormalize::Meta.included_classes
        @klasses.include?(@klass)
      end
    end
  end
end
