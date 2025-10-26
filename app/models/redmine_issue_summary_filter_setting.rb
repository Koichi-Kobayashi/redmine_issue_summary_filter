# frozen_string_literal: true

class RedmineIssueSummaryFilterSetting < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  
  validates :name, presence: true
  validates :filter_conditions, presence: true
  
  serialize :filter_conditions, JSON
end