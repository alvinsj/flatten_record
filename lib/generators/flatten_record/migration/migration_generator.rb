require 'rails/generators/active_record'

module FlattenRecord
  module Generators
    # Migration generator that creates migration file from template
    class MigrationGenerator < ActiveRecord::Generators::Base
      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end
      
      argument :name, :description => 'model'

      def generate_files
        return unless valid? 

        @table_name = klass.table_name
        if klass.table_exists?
          puts "Table already exists: #{@table_name}"
          diff_and_generate 
        else
          @table_columns = denormalized_columns
          migration_template('migration.erb', "db/migrate/create_table_#{@table_name}.rb")    
        end
      end

      private
      def meta
        klass.flattener_meta
      end
 
      def denormalized_columns
        meta.all_columns
      end

      def klass_name
        name.camelize
      end

      def klass
        klass_name.constantize
      end

      def table_name
        klass.table_name
      end

      def flatten_klass_names
        FlattenRecord::Config.included_models
      end

      def diff_and_generate
        if any_diff?
          puts "Generating migration based on the difference.."
          puts "  #{yellow('Other columns(not defined):')} #{extra_columns_names}" unless extra_columns.empty?
          puts "  #{green('Add columns:')} #{add_columns_names}" unless add_columns.empty?

          @migration = "add_#{add_columns.first.name}_and_columns_to"
          
          migration_template('update.erb', "db/migrate/#{@migration}_#{@table_name}.rb")
        end
      end

      def any_diff?
        !add_columns.empty? 
      end

      def add_columns_names
        add_columns.collect(&:name).join(', ')
      end

      def extra_columns_names
        extra_columns.collect(&:name).join(', ')
      end

      def columns
        klass.columns
      end

      def denormalized_column_names
        denormalized_columns.map(&:name)
      end

      def column_names
        columns.map(&:name)
      end

      def add_columns
        @add_columns ||= 
          denormalized_columns.inject([]) do |cols, col|
            if !column_names.include?(col.name)
              cols << col
            end
            cols
          end
      end
      
      def extra_columns
        @extra_columns ||= 
          columns.inject([]) do |cols, col|
            if col.name != 'id' && !denormalized_column_names.include?(col.name)
              cols << col
            end
            cols
          end
      end

      def valid? 
        begin 
          klass && meta
        rescue Exception => e
          puts red(e.message)
          false
        end
      end
      
      def colorize(text, color_code)
        "\e[#{color_code}m#{text}\e[0m"
      end

      def red(text); colorize(text, 31); end
      def green(text); colorize(text, 32); end
      def yellow(text); colorize(text, 33); end
      def blue(text); colorize(text, 34); end

    end
  end
end
