# frozen_string_literal: true

module IssueSummaryFilterHook
  class ViewReportsIssueReportTopHook < Redmine::Hook::ViewListener
    def view_reports_issue_report_top(context = {})
      project = context[:project]
      return '' unless project
      
      # Check if user has permission to view filters
      return '' unless User.current.allowed_to?(:view_issues, project)
      
      # Check if plugin is enabled
      return '' unless Setting.plugin_redmine_issue_summary_filter['show_filter_panel'] == '1'
      
      context[:controller].render_to_string(
        partial: 'reports/filter_panel',
        locals: { project: project }
      )
    end
  end
end