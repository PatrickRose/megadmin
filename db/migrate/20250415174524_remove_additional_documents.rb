class RemoveAdditionalDocuments < ActiveRecord::Migration[7.0]
  def change
    drop_table :additional_documents
  end
end
