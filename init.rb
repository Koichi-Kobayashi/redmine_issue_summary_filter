Rails.logger.info 'Starting Redmine Issue Summary Filter plugin for Redmine'

# Register plugin
Redmine::Plugin.register :redmine_issue_summary_filter do
  name 'Redmine Issue Summary Filter'
  author 'Your Name'
  description 'Adds filtering functionality to issue summary pages'
  version '1.0.0'
  url 'https://github.com/your-repo/redmine_issue_summary_filter'
  author_url 'https://github.com/your-username'

  # Plugin settings
  settings :default => {
    'enable_filter' => '1',
    'default_filter_fields' => 'status,priority,assigned_to',
    'show_filter_panel' => '1'
  }, :partial => 'settings/redmine_issue_summary_filter_settings'

  # Add permission for managing filters
  permission :manage_issue_filters, {
    :redmine_issue_summary_filters => [:index, :show, :create, :update, :destroy]
  }, :require => :member
  
end

# Load plugin files
require_relative 'app/helpers/issue_summary_filter_helper'
require_relative 'app/controllers/redmine_issue_summary_filters_controller'
require_relative 'lib/issue_summary_filter_hook'
require_relative 'lib/issue_summary_filter_reports_extension'

# Load plugin locales
Rails.application.config.i18n.load_path += Dir.glob(File.join(File.dirname(__FILE__), 'config', 'locales', '*.yml'))

# Add hook to display filter panel on issue show page
Rails.application.config.to_prepare do
  Rails.logger.info "=== Redmine Issue Summary Filter Plugin Loading ==="
  
  begin
    unless IssuesController.included_modules.include?(IssueSummaryFilterHelper)
      IssuesController.send(:include, IssueSummaryFilterHelper)
      Rails.logger.info "IssueSummaryFilterHelper included in IssuesController"
    end
    
    unless ReportsController.included_modules.include?(IssueSummaryFilterHelper)
      ReportsController.send(:include, IssueSummaryFilterHelper)
      Rails.logger.info "IssueSummaryFilterHelper included in ReportsController"
    end
    
    unless ReportsController.included_modules.include?(IssueSummaryFilterReportsExtension)
      ReportsController.send(:include, IssueSummaryFilterReportsExtension)
      Rails.logger.info "IssueSummaryFilterReportsExtension included in ReportsController"
    end
    
    Rails.logger.info "=== Plugin Loading Complete ==="
  rescue => e
    Rails.logger.error "Error loading plugin: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end