class AddNameToOrganisers < ActiveRecord::Migration[7.0]
  def change
    add_column :organisers, :name, :string
  end
end
