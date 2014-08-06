module FlattenRecord
  module Meta
    class AssociatedColumn < NormalizedColumn
      def initialize(parent, association, target_model, model)
        super(parent, target_model, model)

        @association = association
      end

      protected
      attr_reader :association
    end
  end
end