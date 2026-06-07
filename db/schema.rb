# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_07_174629) do
  create_table "alert_deliveries", force: :cascade do |t|
    t.integer "alert_rule_id", null: false
    t.integer "attempt_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.integer "failed_message_id"
    t.integer "incident_group_id"
    t.text "last_error"
    t.integer "project_id", null: false
    t.datetime "scheduled_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_rule_id", "status"], name: "index_alert_deliveries_on_alert_rule_id_and_status"
    t.index ["alert_rule_id"], name: "index_alert_deliveries_on_alert_rule_id"
    t.index ["failed_message_id"], name: "index_alert_deliveries_on_failed_message_id"
    t.index ["incident_group_id", "created_at"], name: "index_alert_deliveries_on_incident_group_id_and_created_at"
    t.index ["incident_group_id"], name: "index_alert_deliveries_on_incident_group_id"
    t.index ["project_id", "created_at"], name: "index_alert_deliveries_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_alert_deliveries_on_project_id"
  end

  create_table "alert_rules", force: :cascade do |t|
    t.text "channel_configuration_encrypted", null: false
    t.string "channel_type", null: false
    t.text "conditions_text", null: false
    t.datetime "created_at", null: false
    t.text "escalation_configuration_text"
    t.string "name", null: false
    t.integer "project_id", null: false
    t.string "status", default: "active", null: false
    t.string "trigger_type", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "name"], name: "index_alert_rules_on_project_id_and_name", unique: true
    t.index ["project_id", "status"], name: "index_alert_rules_on_project_id_and_status"
    t.index ["project_id", "trigger_type"], name: "index_alert_rules_on_project_id_and_trigger_type"
    t.index ["project_id"], name: "index_alert_rules_on_project_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id"
    t.string "actor_type", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.text "metadata_text"
    t.integer "organization_id", null: false
    t.integer "project_id"
    t.integer "target_id"
    t.string "target_type", null: false
    t.string "user_agent"
    t.index ["action", "created_at"], name: "index_audit_events_on_action_and_created_at"
    t.index ["actor_type", "actor_id", "created_at"], name: "index_audit_events_on_actor_type_and_actor_id_and_created_at"
    t.index ["organization_id", "created_at"], name: "index_audit_events_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_audit_events_on_organization_id"
    t.index ["project_id", "created_at"], name: "index_audit_events_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_audit_events_on_project_id"
  end

  create_table "failed_messages", force: :cascade do |t|
    t.integer "attempt_count", default: 1, null: false
    t.string "correlation_id"
    t.datetime "created_at", null: false
    t.string "dedup_identity_key", null: false
    t.string "event_type", null: false
    t.string "external_message_id"
    t.text "failure_message_latest", null: false
    t.string "failure_type_latest", null: false
    t.string "fingerprint", null: false
    t.datetime "first_failed_at", null: false
    t.string "idempotency_key"
    t.integer "incident_group_id"
    t.datetime "last_failed_at", null: false
    t.string "latest_consumer_version"
    t.string "latest_replay_status"
    t.text "metadata_text"
    t.datetime "payload_expires_at"
    t.text "payload_original_text", null: false
    t.integer "payload_size_bytes", null: false
    t.integer "project_id", null: false
    t.string "queue_name", null: false
    t.integer "source_id", null: false
    t.string "status", default: "open", null: false
    t.string "tenant_identifier"
    t.datetime "updated_at", null: false
    t.index ["incident_group_id", "status"], name: "index_failed_messages_on_incident_group_id_and_status"
    t.index ["incident_group_id"], name: "index_failed_messages_on_incident_group_id"
    t.index ["project_id", "correlation_id"], name: "index_failed_messages_on_project_id_and_correlation_id"
    t.index ["project_id", "event_type"], name: "index_failed_messages_on_project_id_and_event_type"
    t.index ["project_id", "external_message_id"], name: "index_failed_messages_on_project_id_and_external_message_id"
    t.index ["project_id", "fingerprint"], name: "index_failed_messages_on_project_id_and_fingerprint"
    t.index ["project_id", "latest_replay_status"], name: "index_failed_messages_on_project_id_and_latest_replay_status"
    t.index ["project_id", "queue_name"], name: "index_failed_messages_on_project_id_and_queue_name"
    t.index ["project_id", "source_id", "dedup_identity_key"], name: "idx_on_project_id_source_id_dedup_identity_key_95b712283c", unique: true
    t.index ["project_id", "status", "last_failed_at"], name: "idx_on_project_id_status_last_failed_at_21f8b76b63"
    t.index ["project_id", "tenant_identifier"], name: "index_failed_messages_on_project_id_and_tenant_identifier"
    t.index ["project_id"], name: "index_failed_messages_on_project_id"
    t.index ["source_id"], name: "index_failed_messages_on_source_id"
  end

  create_table "failure_attempts", force: :cascade do |t|
    t.integer "attempt_number", null: false
    t.string "consumer_version"
    t.datetime "created_at", null: false
    t.integer "failed_message_id", null: false
    t.text "failure_message", null: false
    t.string "failure_type", null: false
    t.datetime "occurred_at", null: false
    t.text "stack_trace_text"
    t.datetime "updated_at", null: false
    t.index ["failed_message_id", "attempt_number"], name: "index_failure_attempts_on_failed_message_id_and_attempt_number", unique: true
    t.index ["failed_message_id", "failure_type"], name: "index_failure_attempts_on_failed_message_id_and_failure_type"
    t.index ["failed_message_id", "occurred_at"], name: "index_failure_attempts_on_failed_message_id_and_occurred_at"
    t.index ["failed_message_id"], name: "index_failure_attempts_on_failed_message_id"
  end

  create_table "incident_groups", force: :cascade do |t|
    t.text "consumer_versions_text"
    t.datetime "created_at", null: false
    t.string "event_type"
    t.string "failure_type"
    t.string "fingerprint", null: false
    t.datetime "first_seen_at", null: false
    t.datetime "last_seen_at", null: false
    t.integer "message_count", default: 0, null: false
    t.text "normalized_failure_message"
    t.integer "open_message_count", default: 0, null: false
    t.integer "project_id", null: false
    t.string "queue_name"
    t.string "source_name"
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "failure_type"], name: "index_incident_groups_on_project_id_and_failure_type"
    t.index ["project_id", "fingerprint"], name: "index_incident_groups_on_project_id_and_fingerprint", unique: true
    t.index ["project_id", "queue_name"], name: "index_incident_groups_on_project_id_and_queue_name"
    t.index ["project_id", "status", "last_seen_at"], name: "idx_on_project_id_status_last_seen_at_1144c515b6"
    t.index ["project_id"], name: "index_incident_groups_on_project_id"
  end

  create_table "incident_notes", force: :cascade do |t|
    t.integer "author_user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "incident_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_user_id", "created_at"], name: "index_incident_notes_on_author_user_id_and_created_at"
    t.index ["author_user_id"], name: "index_incident_notes_on_author_user_id"
    t.index ["incident_group_id", "created_at"], name: "index_incident_notes_on_incident_group_id_and_created_at"
    t.index ["incident_group_id"], name: "index_incident_notes_on_incident_group_id"
  end

  create_table "message_notes", force: :cascade do |t|
    t.integer "author_user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "failed_message_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_user_id", "created_at"], name: "index_message_notes_on_author_user_id_and_created_at"
    t.index ["author_user_id"], name: "index_message_notes_on_author_user_id"
    t.index ["failed_message_id", "created_at"], name: "index_message_notes_on_failed_message_id_and_created_at"
    t.index ["failed_message_id"], name: "index_message_notes_on_failed_message_id"
  end

  create_table "message_payload_versions", force: :cascade do |t|
    t.text "change_note"
    t.datetime "created_at", null: false
    t.integer "created_by_user_id", null: false
    t.integer "failed_message_id", null: false
    t.text "payload_text", null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["created_by_user_id"], name: "index_message_payload_versions_on_created_by_user_id"
    t.index ["failed_message_id", "created_at"], name: "idx_on_failed_message_id_created_at_67cf0d60cb"
    t.index ["failed_message_id", "version_number"], name: "idx_on_failed_message_id_version_number_90f4e200b1", unique: true
    t.index ["failed_message_id"], name: "index_message_payload_versions_on_failed_message_id"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "organization_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["organization_id", "role"], name: "index_organization_memberships_on_organization_id_and_role"
    t.index ["organization_id", "user_id"], name: "index_organization_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id", "role"], name: "index_organization_memberships_on_user_id_and_role"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["status"], name: "index_organizations_on_status"
  end

  create_table "project_api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_user_id", null: false
    t.string "key_digest", null: false
    t.string "key_prefix", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.integer "project_id", null: false
    t.datetime "revoked_at"
    t.text "scopes_text", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_project_api_keys_on_created_by_user_id"
    t.index ["project_id", "key_prefix"], name: "index_project_api_keys_on_project_id_and_key_prefix", unique: true
    t.index ["project_id", "revoked_at"], name: "index_project_api_keys_on_project_id_and_revoked_at"
    t.index ["project_id"], name: "index_project_api_keys_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.text "allowed_source_identifiers_text"
    t.datetime "created_at", null: false
    t.string "default_replay_policy", default: "manual_allowed", null: false
    t.integer "default_retention_days", default: 30, null: false
    t.string "environment", default: "production", null: false
    t.integer "max_payload_size_bytes", default: 262144, null: false
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_projects_on_organization_id_and_name", unique: true
    t.index ["organization_id", "slug"], name: "index_projects_on_organization_id_and_slug", unique: true
    t.index ["organization_id", "status"], name: "index_projects_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_projects_on_organization_id"
  end

  create_table "redaction_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "json_path", null: false
    t.integer "project_id", null: false
    t.string "replacement", default: "[REDACTED]", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "json_path"], name: "index_redaction_rules_on_project_id_and_json_path", unique: true
    t.index ["project_id", "status"], name: "index_redaction_rules_on_project_id_and_status"
    t.index ["project_id"], name: "index_redaction_rules_on_project_id"
  end

  create_table "replay_attempts", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "destination_id", null: false
    t.integer "duration_ms"
    t.text "error_message"
    t.string "error_type"
    t.integer "failed_message_id", null: false
    t.integer "http_status_code"
    t.integer "payload_version_id"
    t.integer "replay_batch_id", null: false
    t.text "response_body_truncated"
    t.text "response_headers_text"
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id", "created_at"], name: "index_replay_attempts_on_destination_id_and_created_at"
    t.index ["destination_id"], name: "index_replay_attempts_on_destination_id"
    t.index ["failed_message_id", "created_at"], name: "index_replay_attempts_on_failed_message_id_and_created_at"
    t.index ["failed_message_id"], name: "index_replay_attempts_on_failed_message_id"
    t.index ["payload_version_id"], name: "index_replay_attempts_on_payload_version_id"
    t.index ["replay_batch_id", "failed_message_id"], name: "index_replay_attempts_on_replay_batch_id_and_failed_message_id", unique: true
    t.index ["replay_batch_id", "status"], name: "index_replay_attempts_on_replay_batch_id_and_status"
    t.index ["replay_batch_id"], name: "index_replay_attempts_on_replay_batch_id"
  end

  create_table "replay_batches", force: :cascade do |t|
    t.integer "approved_by_user_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "destination_id", null: false
    t.integer "failure_count", default: 0, null: false
    t.integer "max_concurrency", null: false
    t.datetime "paused_at"
    t.string "payload_selection_mode", default: "original", null: false
    t.integer "pending_count", default: 0, null: false
    t.integer "project_id", null: false
    t.integer "requested_by_user_id", null: false
    t.integer "requests_per_second", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.integer "stop_after_failures"
    t.integer "stop_after_window_seconds"
    t.integer "success_count", default: 0, null: false
    t.integer "total_messages", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_user_id"], name: "index_replay_batches_on_approved_by_user_id"
    t.index ["destination_id", "status"], name: "index_replay_batches_on_destination_id_and_status"
    t.index ["destination_id"], name: "index_replay_batches_on_destination_id"
    t.index ["project_id", "status", "created_at"], name: "index_replay_batches_on_project_id_and_status_and_created_at"
    t.index ["project_id"], name: "index_replay_batches_on_project_id"
    t.index ["requested_by_user_id", "created_at"], name: "index_replay_batches_on_requested_by_user_id_and_created_at"
    t.index ["requested_by_user_id"], name: "index_replay_batches_on_requested_by_user_id"
  end

  create_table "replay_destinations", force: :cascade do |t|
    t.text "allowed_success_statuses_text"
    t.text "authentication_secret_encrypted"
    t.string "authentication_type", default: "none", null: false
    t.datetime "created_at", null: false
    t.string "destination_type", default: "http", null: false
    t.text "headers_text"
    t.string "http_method", default: "POST", null: false
    t.integer "max_requests_per_second"
    t.string "name", null: false
    t.integer "project_id", null: false
    t.string "status", default: "active", null: false
    t.integer "timeout_seconds", default: 10, null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["project_id", "name"], name: "index_replay_destinations_on_project_id_and_name", unique: true
    t.index ["project_id", "status"], name: "index_replay_destinations_on_project_id_and_status"
    t.index ["project_id"], name: "index_replay_destinations_on_project_id"
  end

  create_table "sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "environment"
    t.string "name", null: false
    t.integer "project_id", null: false
    t.string "slug", null: false
    t.string "source_type", default: "http", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "name"], name: "index_sources_on_project_id_and_name", unique: true
    t.index ["project_id", "slug"], name: "index_sources_on_project_id_and_slug", unique: true
    t.index ["project_id", "source_type"], name: "index_sources_on_project_id_and_source_type"
    t.index ["project_id", "status"], name: "index_sources_on_project_id_and_status"
    t.index ["project_id"], name: "index_sources_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "last_sign_in_at"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "alert_deliveries", "alert_rules"
  add_foreign_key "alert_deliveries", "failed_messages"
  add_foreign_key "alert_deliveries", "incident_groups"
  add_foreign_key "alert_deliveries", "projects"
  add_foreign_key "alert_rules", "projects"
  add_foreign_key "audit_events", "organizations"
  add_foreign_key "audit_events", "projects"
  add_foreign_key "failed_messages", "incident_groups"
  add_foreign_key "failed_messages", "projects"
  add_foreign_key "failed_messages", "sources"
  add_foreign_key "failure_attempts", "failed_messages"
  add_foreign_key "incident_groups", "projects"
  add_foreign_key "incident_notes", "incident_groups"
  add_foreign_key "incident_notes", "users", column: "author_user_id"
  add_foreign_key "message_notes", "failed_messages"
  add_foreign_key "message_notes", "users", column: "author_user_id"
  add_foreign_key "message_payload_versions", "failed_messages"
  add_foreign_key "message_payload_versions", "users", column: "created_by_user_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "project_api_keys", "projects"
  add_foreign_key "project_api_keys", "users", column: "created_by_user_id"
  add_foreign_key "projects", "organizations"
  add_foreign_key "redaction_rules", "projects"
  add_foreign_key "replay_attempts", "failed_messages"
  add_foreign_key "replay_attempts", "message_payload_versions", column: "payload_version_id"
  add_foreign_key "replay_attempts", "replay_batches"
  add_foreign_key "replay_attempts", "replay_destinations", column: "destination_id"
  add_foreign_key "replay_batches", "projects"
  add_foreign_key "replay_batches", "replay_destinations", column: "destination_id"
  add_foreign_key "replay_batches", "users", column: "approved_by_user_id"
  add_foreign_key "replay_batches", "users", column: "requested_by_user_id"
  add_foreign_key "replay_destinations", "projects"
  add_foreign_key "sources", "projects"
end
