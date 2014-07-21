module FlattenRecord
  class Observer < ActiveRecord::Observer
    def after_commit(record)
      if @destroyed && @destroyed == record 
        _after_destroy(record)
        @destroy = false
      else
        _after_save(record)
      end
    end

    def after_destroy(record)
      @destroyed = record
    end

    def _after_save(record)
      if denormalized_model
        denormalized_model.create_denormalized(record.reload)
      end
    end

    def _after_destroy(record)
      if denormalized_model
        denormalized_model.destroy_denormalized(record)
      end
    end

    def _create_denormalized(record)
      if denormalized_model
        denormalized_model.create_denormalized(record.reload)
      end
    end

    def _destroy_denormalized(record)
      if denormalized_model
        denormalized_model.destroy_denormalized(record)
      end
    end

    def denormalized_model; nil; end
  end
end
