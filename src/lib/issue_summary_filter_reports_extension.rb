# frozen_string_literal: true

module IssueSummaryFilterReportsExtension
  def self.included(base)
    base.class_eval do
      def issue_report_with_original_filter
        Rails.logger.info "=== Issue Summary Filter Extension Called ==="
        Rails.logger.info "Filter params: #{params[:filter].inspect}"
        
        # Parse and permit filter parameters
        filter_conditions = {}
        @saved_filter_params = params[:filter] # Save for view rendering
        
        if params[:filter]
          begin
            filter_params = params[:filter].permit! if params[:filter].respond_to?(:permit!)
            params[:filter] = filter_params if filter_params
            @saved_filter_params = filter_params # Save the permitted params
            Rails.logger.info "Permitted filter params: #{params[:filter].inspect}"
            
            # Build filter conditions
            if params[:filter] && params[:filter].to_h
              filter_hash = params[:filter].to_h
              
              filter_hash.each do |key, values|
                if values.is_a?(Array) && values.any?(&:present?)
                  filter_conditions[key.to_sym] = values.reject(&:blank?).map(&:to_i)
                  Rails.logger.info "Added #{key} condition: #{filter_conditions[key.to_sym]}"
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
        
        # Call the original method
        issue_report_without_plugin_filtering
        
        # Restore filter
        params[:filter] = old_filter if old_filter
        
        # Apply filters to the data
        if filter_conditions.any?
          Rails.logger.info "Applying filter conditions: #{filter_conditions.inspect}"
          
          # Filter each report data array
          filter_report_data_direct(filter_conditions)
          
          Rails.logger.info "After filter - @issues_by_tracker count: #{@issues_by_tracker&.size || 0}"
        end
      end
      
      alias_method :issue_report_without_plugin_filtering, :issue_report
      alias_method :issue_report, :issue_report_with_original_filter
      
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
      
      def filter_report_data_direct(filter_conditions)
        Rails.logger.info "Filtering report data directly with conditions: #{filter_conditions.inspect}"
        
        with_subprojects = Setting.display_subprojects_issues?
        base_scope = Issue.visible.where(@project.project_condition(with_subprojects))
        
        # Apply filter conditions globally
        if filter_conditions.any?
          filter_scope = base_scope.where(filter_conditions)
        else
          filter_scope = base_scope
        end
        
        Rails.logger.info "Base scope count: #{base_scope.count}"
        Rails.logger.info "Filtered scope count: #{filter_scope.count}"
        
        # Filter each report data array with correct field key mappings
        field_mapping = {
          'tracker' => { field_key: :tracker_id, instance_var: :@issues_by_tracker },
          'version' => { field_key: :fixed_version_id, instance_var: :@issues_by_version },
          'priority' => { field_key: :priority_id, instance_var: :@issues_by_priority },
          'category' => { field_key: :category_id, instance_var: :@issues_by_category },
          'assigned_to' => { field_key: :assigned_to_id, instance_var: :@issues_by_assigned_to },
          'author' => { field_key: :author_id, instance_var: :@issues_by_author },
          'subproject' => { field_key: :project_id, instance_var: :@issues_by_subproject }
        }
        
        field_mapping.each do |field_name, config|
          field_key = config[:field_key]
          instance_var = config[:instance_var]
          
          original_data = instance_variable_get(instance_var)
          next unless original_data.is_a?(Array) && original_data.any?
          
          Rails.logger.info "Filtering #{field_name} data with field_key: #{field_key}..."
          
          # Get unique field values from original data
          unique_values = original_data.map { |entry| entry[field_key.to_s] }.uniq
          
          filtered_data = []
          
          unique_values.each do |field_value|
            # Count issues matching the field and filter conditions
            if field_value.present?
              field_condition = { field_key => field_value }
            else
              field_condition = { field_key => nil }
            end
            
            count_scope = filter_scope.where(field_condition)
            
            # Only include if there are matching issues
            if count_scope.any?
              # Get status counts
              status_counts = count_scope.joins(:status)
                                        .group(:status_id, :is_closed)
                                        .count
              
              status_counts.each do |(status_id, is_closed), count|
                is_closed_bool = ['t', 'true', '1'].include?(is_closed.to_s)
                
                entry = {
                  "status_id" => status_id.to_s,
                  "closed" => is_closed_bool,
                  field_key.to_s => field_value.to_s,
                  "total" => count.to_s
                }
                
                filtered_data << entry
              end
            end
          end
          
          instance_variable_set(instance_var, filtered_data)
          Rails.logger.info "Filtered #{field_name} data count: #{filtered_data.size}"
        end
      end
      
    end
  end
end