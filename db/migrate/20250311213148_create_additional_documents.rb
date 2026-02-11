class CreateAdditionalDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :additional_documents do |t|
      t.belongs_to :event, foreign_key: true

      t.timestamps
    end
  end
end
