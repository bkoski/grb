class MilestonesController < ApplicationController

  def update_sort_order
    target_obj = Milestone.find(params[:target_id])
    target_obj.relative_sort(params[:anchor], params[:anchor_id])
    head 200
  end

  def update
    @milestone = Milestone.find_by(title: params[:title])
    @milestone.set_status!(params[:status]) if params[:status]
    head 200
  end

end