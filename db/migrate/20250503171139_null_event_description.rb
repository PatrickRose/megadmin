class NullEventDescription < ActiveRecord::Migration[7.0]
  def change
    change_column_null :events, :description, true
  end
end
