class BoardsController < ApplicationController

  def show
    @milestones = Issue.distinct(:milestone)
    @issues_by_milestone = Issue.all.group_by(&:milestone)

    @contributors = Contributor.all
    @issues_by_milestone['Backlog'] = @issues_by_milestone[nil]
    @milestones << 'Backlog'
  end

  def user
    @contributor        = Contributor.find_by(login: params[:login])
    @title              = "@#{@contributor.login}'s Issues"
    @issues = Issue.where(assignee: params[:login]).all
    @active_milestones = Milestone.active.map(&:title) & @issues.map(&:milestone)
    @backlog_issues = []
  end

  def milestone
    @title            = params[:title]
    @milestone        = Milestone.find_by(title: params[:title])
    @issues           = Issue.where(milestone: params[:title], state: 'open').all.to_a
    @issues           += Issue.closed_today.where(milestone: params[:title]).all.to_a
    @recently_closed_issues = @milestone.issues.closed_today.desc(:closed_at)
    @recent_commits   = @milestone.commits.today.desc(:committed_at)
    @other_commits    = @milestone.commits.where(number: nil).today.all
  end

  def list_milestones
    @title = "All Milestones"
    @milestones = Milestone.all
  end

end