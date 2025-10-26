# frozen_string_literal: true

class CreateRedmineIssueSummaryFilterSettings < ActiveRecord::Migration[5.2]
  def change
    unless table_exists?(:redmine_issue_summary_filter_settings)
      create_table :redmine_issue_summary_filter_settings do |t|
        t.integer :project_id, null: false
        t.integer :user_id, null: false
        t.string :name, null: false
        t.text :filter_conditions, null: false
        t.timestamps
      end
      
      add_foreign_key :redmine_issue_summary_filter_settings, :projects, column: :project_id
      add_foreign_key :redmine_issue_summary_filter_settings, :users, column: :user_id
      add_index :redmine_issue_summary_filter_settings, [:project_id, :user_id], name: 'idx_risfs_project_user'
    end
  end
end