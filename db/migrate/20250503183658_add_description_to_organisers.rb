class AddDescriptionToOrganisers < ActiveRecord::Migration[7.0]
  def change
    add_column :organiser_to_events, :description, :string
  end
end
