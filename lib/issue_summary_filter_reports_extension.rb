# frozen_string_literal: true

module IssueSummaryFilterReportsExtension
  def self.included(base)
    base.class_eval do
      alias_method :issue_report_without_filter, :issue_report
      
      def issue_report
        Rails.logger.info "=== Issue Summary Filter Debug ==="
        Rails.logger.info "Filter params: #{params[:filter].inspect}"
        
        if params[:filter]
          params[:filter] = params[:filter].permit(
            status_id: [], priority_id: [], assigned_to_id: [], 
            tracker_id: [], category_id: [], fixed_version_id: []
          )
          Rails.logger.info "Permitted filter params: #{params[:filter].inspect}"
        end
        
        issue_report_without_filter
        
        if params[:filter] && params[:filter].permitted? && params[:filter].to_h.any? { |k, v| v.is_a?(Array) ? v.any?(&:present?) : v.present? }
          Rails.logger.info "Applying filter to reports..."
          apply_filter_to_reports
          @filtered_issues = apply_filter_to_issues
        else
          Rails.logger.info "No filter applied"
        end
      end
      
      private
      
      def apply_filter_to_reports
        conditions = build_filter_conditions
        Rails.logger.info "Filter conditions: #{conditions.inspect}"
        return if conditions.empty?
        
        with_subprojects = Setting.display_subprojects_issues?
        
        Rails.logger.info "Original @issues_by_tracker type: #{@issues_by_tracker.class}"
        Rails.logger.info "Original @issues_by_tracker sample: #{@issues_by_tracker.first(2).inspect}" if @issues_by_tracker.is_a?(Array)
        
        if @issues_by_tracker.is_a?(Array)
          @issues_by_tracker = filter_report_data(@issues_by_tracker, conditions, with_subprojects, :tracker_id)
          Rails.logger.info "Filtered @issues_by_tracker count: #{@issues_by_tracker.size}"
        end
        
        if @issues_by_version.is_a?(Array)
          @issues_by_version = filter_report_data(@issues_by_version, conditions, with_subprojects, :fixed_version_id)
        end
        
        if @issues_by_priority.is_a?(Array)
          @issues_by_priority = filter_report_data(@issues_by_priority, conditions, with_subprojects, :priority_id)
        end
        
        if @issues_by_category.is_a?(Array)
          @issues_by_category = filter_report_data(@issues_by_category, conditions, with_subprojects, :category_id)
        end
        
        if @issues_by_assigned_to.is_a?(Array)
          @issues_by_assigned_to = filter_report_data(@issues_by_assigned_to, conditions, with_subprojects, :assigned_to_id)
        end
        
        if @issues_by_author.is_a?(Array)
          @issues_by_author = filter_report_data(@issues_by_author, conditions, with_subprojects, :author_id)
        end
        
        if @issues_by_subproject.is_a?(Array)
          @issues_by_subproject = filter_report_data(@issues_by_subproject, conditions, with_subprojects, :project_id)
        end
      end
      
      def filter_report_data(original_data, conditions, with_subprojects, field_key)
        Rails.logger.info "Filtering report data for #{field_key} with conditions: #{conditions.inspect}"
        return original_data if conditions.empty?
        
        base_scope = Issue.visible.where(@project.project_condition(with_subprojects))
        filtered_issues = base_scope.where(conditions)
        
        Rails.logger.info "Base scope count: #{base_scope.count}"
        Rails.logger.info "Filtered issues count: #{filtered_issues.count}"
        
        filtered_data = []
        
        original_data.each do |data_entry|
          field_value = data_entry[field_key.to_s]
          Rails.logger.info "Processing field_value: #{field_value} for #{field_key}"
          
          if field_value.present?
            count_scope = filtered_issues.where(field_key => field_value)
          else
            count_scope = filtered_issues.where(field_key => nil)
          end
          
          Rails.logger.info "Count scope for #{field_value}: #{count_scope.count}"
          
          status_counts = count_scope.joins(:status)
                                   .group(:status_id, :is_closed)
                                   .count
          
          Rails.logger.info "Status counts for #{field_value}: #{status_counts.inspect}"
          
          status_counts.each do |(status_id, is_closed), count|
            is_closed_bool = ['t', 'true', '1'].include?(is_closed.to_s)
            filtered_data << {
              "status_id" => status_id.to_s,
              "closed" => is_closed_bool,
              field_key.to_s => field_value.to_s,
              "total" => count.to_s
            }
          end
        end
        
        Rails.logger.info "Filtered data count: #{filtered_data.size}"
        filtered_data
      end
      
      def apply_filter_to_issues
        conditions = build_filter_conditions
        
        if conditions.any?
          with_subprojects = Setting.display_subprojects_issues?
          base_query = Issue.visible.where(conditions)
                           .where(@project.project_condition(with_subprojects))
          
          @filtered_issues_count = base_query.count
          
          @filtered_issues = base_query.includes(:tracker, :status, :priority, :assigned_to)
                                      .order(:updated_on => :desc)
                                      .limit(50)
        else
          @filtered_issues_count = 0
          @filtered_issues = []
        end
      end
      
      def build_filter_conditions
        conditions = {}
        
        if params[:filter] && params[:filter].permitted?
          filter_params = params[:filter].to_h
          
          if filter_params[:status_id].present? && filter_params[:status_id].any?(&:present?)
            conditions[:status_id] = filter_params[:status_id].reject(&:blank?)
          end
          
          if filter_params[:priority_id].present? && filter_params[:priority_id].any?(&:present?)
            conditions[:priority_id] = filter_params[:priority_id].reject(&:blank?)
          end
          
          if filter_params[:assigned_to_id].present? && filter_params[:assigned_to_id].any?(&:present?)
            conditions[:assigned_to_id] = filter_params[:assigned_to_id].reject(&:blank?)
          end
          
          if filter_params[:tracker_id].present? && filter_params[:tracker_id].any?(&:present?)
            conditions[:tracker_id] = filter_params[:tracker_id].reject(&:blank?)
          end
          
          if filter_params[:category_id].present? && filter_params[:category_id].any?(&:present?)
            conditions[:category_id] = filter_params[:category_id].reject(&:blank?)
          end
          
          if filter_params[:fixed_version_id].present? && filter_params[:fixed_version_id].any?(&:present?)
            conditions[:fixed_version_id] = filter_params[:fixed_version_id].reject(&:blank?)
          end
          
          Rails.logger.info "Built filter conditions: #{conditions.inspect}"
        end
        
        conditions
      end
    end
  end
end