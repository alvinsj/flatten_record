module FlattenRecord
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload
 
  module Meta
    def self.autoload_nodes
      path =  "#{File.dirname(__FILE__)}/flatten_record/meta/"
      dir = Dir["#{path}*.rb"]
    
      dir.each do|file|
        file_name = file.gsub(path, '')[0..-4]
        klass_name = file_name.camelize.to_sym 
        
        autoload klass_name, "flatten_record/meta/#{file_name}"
      end
    end

    autoload_nodes
  end
  
  autoload :Flattener, 'flatten_record/flattener'
  autoload :Definition, 'flatten_record/definition'
  
  autoload :AddDefinitionMethods, 'flatten_record/denormalize/add_definition_methods'
  autoload :AddDenormalizationMethods, 'flatten_record/denormalize/add_denormalization_methods'
  
  autoload :DenormalizerMeta, 'flatten_record/denormalizer_meta'
  autoload :Denormalizer, 'flatten_record/denormalizer'
  autoload :DenormalizerHook, 'flatten_record/denormalizer_hook'
  autoload :Denormalize, 'flatten_record/denormalize'
  autoload :Observer, 'flatten_record/observer'
end
