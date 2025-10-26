# frozen_string_literal: true

module IssueSummaryFilterReportsExtension
  def self.included(base)
    base.class_eval do
      def issue_report_with_original_filter
        # Parse and permit filter parameters
        filter_conditions = {}
        @saved_filter_params = params[:filter] # Save for view rendering
        
        if params[:filter]
          begin
            filter_params = params[:filter].permit! if params[:filter].respond_to?(:permit!)
            params[:filter] = filter_params if filter_params
            @saved_filter_params = filter_params # Save the permitted params
            
            # Build filter conditions
            if params[:filter] && params[:filter].to_h
              filter_hash = params[:filter].to_h
              
              filter_hash.each do |key, values|
                if values.is_a?(Array) && values.any?(&:present?)
                  filter_conditions[key.to_sym] = values.reject(&:blank?).map(&:to_i)
                elsif key.to_s == 'created_on_from' && values.present?
                  filter_conditions[:created_on_from] = values
                elsif key.to_s == 'created_on_to' && values.present?
                  filter_conditions[:created_on_to] = values
                elsif key.to_s == 'updated_on_from' && values.present?
                  filter_conditions[:updated_on_from] = values
                elsif key.to_s == 'updated_on_to' && values.present?
                  filter_conditions[:updated_on_to] = values
                end
              end
            end
          rescue => e
            Rails.logger.error "Error parsing filter: #{e.message}"
          end
        end
        
        # Temporarily remove filter from params before calling original
        old_filter = params[:filter]
        params.delete(:filter)
        
        # If filters exist, get filtered data BEFORE calling original method
        if filter_conditions.any?
          # Get filtered data before original method is called
          get_filtered_report_data(filter_conditions)
        else
          # Call the original method if no filters
          issue_report_without_plugin_filtering
        end
        
        # Restore filter
        params[:filter] = old_filter if old_filter
      end
      
      def get_filtered_report_data(filter_conditions)
        with_subprojects = Setting.display_subprojects_issues?
        
        # Set up the basic data structures
        @trackers = @project.rolled_up_trackers(with_subprojects).visible
        @versions = @project.shared_versions.sorted + [Version.new(:name => "[#{l(:label_none)}]")]
        @priorities = IssuePriority.all.reverse
        @categories = @project.issue_categories + [IssueCategory.new(:name => "[#{l(:label_none)}]")]
        @assignees = (Setting.issue_group_assignment? ? @project.principals : @project.users).sorted + [User.new(:firstname => "[#{l(:label_none)}]")]
        @authors = @project.users.sorted
        @subprojects = @project.descendants.visible
        
        # Get base issue scope with filters
        base_scope = Issue.visible.where(@project.project_condition(with_subprojects))
        
        # Apply regular filter conditions (excluding date conditions)
        filtered_scope = base_scope.where(filter_conditions.reject { |k| [:created_on_from, :created_on_to, :updated_on_from, :updated_on_to].include?(k) })
        
        # Apply created_on date conditions separately
        if filter_conditions[:created_on_from].present?
          filtered_scope = filtered_scope.where('issues.created_on >= ?', filter_conditions[:created_on_from])
        end
        
        if filter_conditions[:created_on_to].present?
          # Include the entire end date (until end of day)
          filtered_scope = filtered_scope.where('issues.created_on <= ?', "#{filter_conditions[:created_on_to]} 23:59:59")
        end
        
        # Apply updated_on date conditions separately
        if filter_conditions[:updated_on_from].present?
          filtered_scope = filtered_scope.where('issues.updated_on >= ?', filter_conditions[:updated_on_from])
        end
        
        if filter_conditions[:updated_on_to].present?
          # Include the entire end date (until end of day)
          filtered_scope = filtered_scope.where('issues.updated_on <= ?', "#{filter_conditions[:updated_on_to]} 23:59:59")
        end
        
        # Get statuses for the view
        @statuses = @project.rolled_up_statuses
        
        # Build filtered report data
        @issues_by_tracker = build_filtered_by_tracker(filtered_scope, @trackers)
        @issues_by_version = build_filtered_by_version(filtered_scope, @versions)
        @issues_by_priority = build_filtered_by_priority(filtered_scope, @priorities)
        @issues_by_category = build_filtered_by_category(filtered_scope, @categories)
        @issues_by_assigned_to = build_filtered_by_assigned_to(filtered_scope, @assignees)
        @issues_by_author = build_filtered_by_author(filtered_scope, @authors)
        @issues_by_subproject = build_filtered_by_subproject(filtered_scope, @subprojects) || []
      end
      
      def build_filtered_by_tracker(scope, trackers)
        data = []
        scope.joins(:tracker).joins(:status)
             .group(:tracker_id, :status_id, :is_closed)
             .count
             .each do |(tracker_id, status_id, is_closed), count|
          data << {
            "tracker_id" => tracker_id.to_s,
            "status_id" => status_id.to_s,
            "closed" => ['t', 'true', '1'].include?(is_closed.to_s),
            "total" => count.to_s
          }
        end
        data
      end
      
      def build_filtered_by_version(scope, versions)
        data = []
        scope.left_joins(:fixed_version).joins(:status)
             .group(:fixed_version_id, :status_id, :is_closed)
             .count
             .each do |(version_id, status_id, is_closed), count|
          data << {
            "fixed_version_id" => version_id.to_s,
            "status_id" => status_id.to_s,
            "closed" => ['t', 'true', '1'].include?(is_closed.to_s),
            "total" => count.to_s
          }
        end
        data
      end
      
      def build_filtered_by_priority(scope, priorities)
        data = []
        scope.joins(:priority).joins(:status)
             .group(:priority_id, :status_id, :is_closed)
             .count
             .each do |(priority_id, status_id, is_closed), count|
          data << {
            "priority_id" => priority_id.to_s,
            "status_id" => status_id.to_s,
            "closed" => ['t', 'true', '1'].include?(is_closed.to_s),
            "total" => count.to_s
          }
        end
        data
      end
      
      def build_filtered_by_category(scope, categories)
        data = []
        scope.left_joins(:category).joins(:status)
             .group(:category_id, :status_id, :is_closed)
             .count
             .each do |(category_id, status_id, is_closed), count|
          data << {
            "category_id" => category_id.to_s,
            "status_id" => status_id.to_s,
            "closed" => ['t', 'true', '1'].include?(is_closed.to_s),
            "total" => count.to_s
          }
        end
        data
      end
      
      def build_filtered_by_assigned_to(scope, assignees)
        data = []
        scope.left_joins(:assigned_to).joins(:status)
             .group(:assigned_to_id, :status_id, :is_closed)
             .count
             .each do |(assigned_to_id, status_id, is_closed), count|
          data << {
            "assigned_to_id" => assigned_to_id.to_s,
            "status_id" => status_id.to_s,
            "closed" => ['t', 'true', '1'].include?(is_closed.to_s),
            "total" => count.to_s
          }
        end
        data
      end
      
      def build_filtered_by_author(scope, authors)
        data = []
        scope.joins(:author).joins(:status)
             .group(:author_id, :status_id, :is_closed)
             .count
             .each do |(author_id, status_id, is_closed), count|
          data << {
            "author_id" => author_id.to_s,
            "status_id" => status_id.to_s,
            "closed" => ['t', 'true', '1'].include?(is_closed.to_s),
            "total" => count.to_s
          }
        end
        data
      end
      
      def build_filtered_by_subproject(scope, subprojects)
        data = []
        scope.joins(:project).joins(:status)
             .group(:project_id, :status_id, :is_closed)
             .count
             .each do |(project_id, status_id, is_closed), count|
          data << {
            "project_id" => project_id.to_s,
            "status_id" => status_id.to_s,
            "closed" => ['t', 'true', '1'].include?(is_closed.to_s),
            "total" => count.to_s
          }
        end
        data
      end
      
      def filter_report_data_direct(filter_conditions)
        # This method is no longer used, but kept for compatibility
      end
      
      alias_method :issue_report_without_plugin_filtering, :issue_report
      alias_method :issue_report, :issue_report_with_original_filter
      
      private
      
      def build_filter_conditions
        conditions = {}
        
        Rails.logger.info "=== Building Filter Conditions ==="
        Rails.logger.info "params[:filter]: #{params[:filter].inspect}"
        Rails.logger.info "Using saved filter: #{@saved_filter_params.inspect}"
        
        filter_params = @saved_filter_params || params[:filter]
        
        if filter_params && filter_params.permitted?
          filter_params = filter_params.to_h
          Rails.logger.info "filter_params: #{filter_params.inspect}"
          
          if filter_params[:status_id].present? && filter_params[:status_id].any?(&:present?)
            conditions[:status_id] = filter_params[:status_id].reject(&:blank?)
            Rails.logger.info "Added status_id condition: #{conditions[:status_id]}"
          end
          
          if filter_params[:priority_id].present? && filter_params[:priority_id].any?(&:present?)
            conditions[:priority_id] = filter_params[:priority_id].reject(&:blank?)
            Rails.logger.info "Added priority_id condition: #{conditions[:priority_id]}"
          end
          
          if filter_params[:assigned_to_id].present? && filter_params[:assigned_to_id].any?(&:present?)
            conditions[:assigned_to_id] = filter_params[:assigned_to_id].reject(&:blank?)
            Rails.logger.info "Added assigned_to_id condition: #{conditions[:assigned_to_id]}"
          end
          
          if filter_params[:tracker_id].present? && filter_params[:tracker_id].any?(&:present?)
            conditions[:tracker_id] = filter_params[:tracker_id].reject(&:blank?)
            Rails.logger.info "Added tracker_id condition: #{conditions[:tracker_id]}"
          end
          
          if filter_params[:category_id].present? && filter_params[:category_id].any?(&:present?)
            conditions[:category_id] = filter_params[:category_id].reject(&:blank?)
            Rails.logger.info "Added category_id condition: #{conditions[:category_id]}"
          end
          
          if filter_params[:fixed_version_id].present? && filter_params[:fixed_version_id].any?(&:present?)
            conditions[:fixed_version_id] = filter_params[:fixed_version_id].reject(&:blank?)
            Rails.logger.info "Added fixed_version_id condition: #{conditions[:fixed_version_id]}"
          end
          
          Rails.logger.info "Final conditions: #{conditions.inspect}"
        end
        
        conditions
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
        
        # Remove the current field key from conditions to avoid redundant filtering
        filter_conditions = conditions.dup
        filter_conditions.delete(field_key)
        Rails.logger.info "After removing #{field_key}, filter_conditions: #{filter_conditions.inspect}"
        
        base_scope = Issue.visible.where(@project.project_condition(with_subprojects))
        
        # Apply all filter conditions except the current field
        if filter_conditions.any?
          filtered_issues = base_scope.where(filter_conditions)
        else
          filtered_issues = base_scope
        end
        
        Rails.logger.info "Base scope count: #{base_scope.count}"
        Rails.logger.info "Filtered issues count: #{filtered_issues.count}"
        
        filtered_data = []
        
        # Get unique field values from the original data to maintain the report structure
        unique_field_values = original_data.map { |entry| entry[field_key.to_s] }.uniq
        
        unique_field_values.each do |field_value|
          Rails.logger.info "Processing field_value: #{field_value} for #{field_key}"
          
          if field_value.present?
            count_scope = filtered_issues.where(field_key => field_value)
          else
            count_scope = filtered_issues.where(field_key => nil)
          end
          
          Rails.logger.info "Count scope for #{field_value}: #{count_scope.count}"
          
          # Only add data if there are matching issues
          if count_scope.any?
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
          else
            Rails.logger.info "No matching issues for #{field_value}, skipping"
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
      
    end
  end
end
