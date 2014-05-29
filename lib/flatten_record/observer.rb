module FlattenRecord
  class Observer < ActiveRecord::Observer
    def after_save(record)
      if denormalized_model
        denormalized_model.create_denormalized(record.reload)
      end
    end

    def after_destroy(record)
      if denormalized_model
        denormalized_model.destroy_denormalized(record)
      end
    end

    def denormalized_model; nil; end
  end
end
