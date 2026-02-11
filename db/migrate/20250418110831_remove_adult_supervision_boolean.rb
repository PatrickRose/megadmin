class RemoveAdultSupervisionBoolean < ActiveRecord::Migration[7.0]
  def change
    remove_column :events, :adult_supervision_required
  end
end
