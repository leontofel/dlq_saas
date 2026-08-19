class AddPayloadIdentityDigestToFailedMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :failed_messages, :payload_identity_digest, :string
  end
end
