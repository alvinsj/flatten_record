module FlattenRecord
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload

  autoload :AddDefinitionMethods, 'flatten_record/denormalize/add_definition_methods'
  autoload :AddDenormalizationMethods, 'flatten_record/denormalize/add_denormalization_methods'
  
  autoload :DenormalizerMeta, 'flatten_record/denormalizer_meta'
  autoload :Denormalizer, 'flatten_record/denormalizer'
  autoload :DenormalizerHook, 'flatten_record/denormalizer_hook'
  autoload :Denormalize, 'flatten_record/denormalize'
  autoload :Observer, 'flatten_record/observer'
end
