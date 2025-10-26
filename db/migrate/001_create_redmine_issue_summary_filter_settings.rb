# frozen_string_literal: true

class CreateRedmineIssueSummaryFilterSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :redmine_issue_summary_filter_settings do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :filter_conditions, null: false
      t.timestamps
    end
    
    add_index :redmine_issue_summary_filter_settings, [:project_id, :user_id]
  end
end