class IssuesController < ApplicationController

  def update_sort_order
    target_obj = Issue.find(params[:target_id])
    target_obj.relative_sort(params[:anchor], params[:anchor_id])
    head 200
  end

  def create
    head 200
  end

  def update
    @issue = Issue.find(params[:id])
    @issue.assign_to(params[:assignee]) if params[:assignee]
    @issue.set_status!(params[:status]) if params[:status]
    head 200
  end

end