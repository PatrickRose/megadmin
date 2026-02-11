class AddAdultSupervisionRequiredBoolean < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :adult_supervision_required, :bool
  end
end
