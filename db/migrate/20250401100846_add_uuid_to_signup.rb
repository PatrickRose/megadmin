class AddUuidToSignup < ActiveRecord::Migration[7.0]
  def change
    add_column :event_signups, :uuid, :string
  end
end
