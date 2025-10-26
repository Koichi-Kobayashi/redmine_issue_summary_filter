# frozen_string_literal: true

module IssueSummaryFilterHook
  # 複数のフックポイントを試す
  class ViewReportsIssueReportTopHook < Redmine::Hook::ViewListener
    def view_reports_issue_report_top(context = {})
      render_filter_panel(context)
    end
    
    def view_reports_issue_report_bottom(context = {})
      # 下部にも表示（確実に表示されるように）
      render_filter_panel(context)
    end
    
    def view_layouts_base_body_bottom(context = {})
      # レポートページでのみ表示
      if context[:controller].controller_name == 'reports' && context[:controller].action_name == 'issue_report'
        render_filter_panel(context)
      else
        ''
      end
    end
    
    private
    
    def render_filter_panel(context)
      project = context[:project]
      return '' unless project
      
      # Check if user has permission to view issues
      return '' unless User.current.allowed_to?(:view_issues, project)
      
      Rails.logger.info "=== Issue Summary Filter Hook Debug ==="
      Rails.logger.info "Hook called from: #{caller[0]}"
      Rails.logger.info "Project: #{project.name}"
      Rails.logger.info "User: #{User.current.name}"
      Rails.logger.info "Controller: #{context[:controller].controller_name}"
      Rails.logger.info "Action: #{context[:controller].action_name}"
      
      begin
        # Get filter params from controller instance variable if available
        controller = context[:controller]
        filter_params = if controller.instance_variable_defined?(:@saved_filter_params)
          controller.instance_variable_get(:@saved_filter_params)
        else
          controller.params[:filter]
        end
        
        Rails.logger.info "Filter params for view: #{filter_params.inspect}"
        
        result = context[:controller].render_to_string(
          partial: 'reports/filter_panel',
          locals: { project: project, filter_params: filter_params }
        )
        Rails.logger.info "Filter panel rendered successfully, length: #{result.length}"
        result
      rescue => e
        Rails.logger.error "Error rendering filter panel: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        ''
      end
    end
  end
end