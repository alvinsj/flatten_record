module FlattenRecord
  class Definition 
    def initialize(definition)
      @definition = definition
      @errors = []
      @methods = []
      @include = {}
      @except = []
      @only = []
    end
    
    def [](key)
      instance_variable_get "@#{key}"
    end

    def validates_with(target_model, model)
      @target_model = target_model
      @model = model

      @definition.each do |key, value|
        validates(key, value)
      end
    end

    def validates(key, value)
      if protected_methods.include?("validate_#{key}".to_sym)
        send("validate_#{key}", value)    
      else
        @errors << "unknown options '#{key}'"
      end
      self
    end

    def error_message
      @errors.join("\n")
    end

    def valid?
      @errors.blank?
    end

    protected   
    def validate_except(attrs)
      attrs.each do |attr|
        error = "unknown attributes '#{attr}' in #{@target_model.name.to_s}"
        @errors << error unless target_attr?(attr)
        @except << attr
      end
    end
    alias_method :validate_only, :validate_except
   
    def validate_methods(methods)
      methods.each do |method| 
        error = "undefined method '#{method}' in #{@model.name.to_s}"
        @errors << error unless model_method?(method)
        @methods << method
      end      
    end

    def validate_include(childs)
      childs.each do |child, child_definition|
        error = "unknown association '#{child}' in '#{@target_model.name.to_s}'"
        assoc = @target_model.reflect_on_association(child)
        @errors << error if assoc.blank?
        @include.merge!({ child => Definition.new(child_definition) })
      end
    end

    private
    def target_attr?(attr)
      @target_model.respond_to?(attr)
    end
    
    def model_method?(method)
      @model.method_defined?(method) 
    end
  end
end
