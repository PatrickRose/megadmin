class AddDraftToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :draft, :boolean
  end
end
