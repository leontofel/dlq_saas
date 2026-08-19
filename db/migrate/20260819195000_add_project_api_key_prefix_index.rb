class AddProjectApiKeyPrefixIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :project_api_keys, :key_prefix
  end
end
