module FlattenRecord
  class Observer < ActiveRecord::Observer
    
    def after_commit(record)
      #puts "wwwww: #{record.send(:transaction_include_action?, :create)}"
      #puts "wwwww: #{record.send(:transaction_include_action?, :update)}"
      #puts "ggggg: #{record.send(:transaction_include_action?, :destroy)}"
      _after_save(record) if record.send(:transaction_include_action?, :create) || record.send(:transaction_include_action?, :update)

      _after_destroy(record) if record.send(:transaction_include_action?, :destroy)
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
