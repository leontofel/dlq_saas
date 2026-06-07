class CreateFailureAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :failure_attempts do |t|
      t.references :failed_message, null: false, foreign_key: true
      t.integer :attempt_number, null: false
      t.string :failure_type, null: false
      t.text :failure_message, null: false
      t.text :stack_trace_text
      t.string :consumer_version
      t.datetime :occurred_at, null: false

      t.timestamps

      t.index [ :failed_message_id, :attempt_number ], unique: true
      t.index [ :failed_message_id, :occurred_at ]
      t.index [ :failed_message_id, :failure_type ]
    end
  end
end
