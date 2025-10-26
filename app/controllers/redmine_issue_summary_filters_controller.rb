# frozen_string_literal: true

class RedmineIssueSummaryFiltersController < ApplicationController
  before_action :find_project
  before_action :authorize
  
  def index
    @filters = RedmineIssueSummaryFilterSetting.where(project: @project, user: User.current)
  end
  
  def show
    @filter = RedmineIssueSummaryFilterSetting.find(params[:id])
  end
  
  def create
    @filter = RedmineIssueSummaryFilterSetting.new(filter_params)
    @filter.project = @project
    @filter.user = User.current
    
    if @filter.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_redmine_issue_summary_filters_path(@project)
    else
      render :new
    end
  end
  
  def update
    @filter = RedmineIssueSummaryFilterSetting.find(params[:id])
    
    if @filter.update(filter_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_redmine_issue_summary_filters_path(@project)
    else
      render :edit
    end
  end
  
  def destroy
    @filter = RedmineIssueSummaryFilterSetting.find(params[:id])
    @filter.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_redmine_issue_summary_filters_path(@project)
  end
  
  private
  
  def filter_params
    params.require(:redmine_issue_summary_filter_setting).permit(:name, :filter_conditions)
  end
end