module FlattenRecord
  module DenormalizerHook
    def self.included(base)
      base.class_eval %Q{
        after_save :_create_denormalized_record
        after_destroy :_delete_denormalized_record
      }
    end

    private  
    def _create_denormalized_record
      self.class.denormalized_models.each{|dm| dm.create_denormalized(self)}
    end

    def _delete_denormalized_record
      self.class.denormalized_models.each{|dm| dm.destroy_denormalized(self)}
    end
 
  end
end
