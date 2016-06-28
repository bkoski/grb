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
    @issues = Issue.where(assignee: params[:login]).open.all
    @active_milestones = Milestone.active.map(&:title) & @issues.map(&:milestone)
    @backlog_issues = []
  end

  def user_commits
    params[:days] ||= 7
    @contributor     = Contributor.find_by(login: params[:login])
    @title           = "@#{@contributor.login}'s Commits"
    @commits_by_date = Commit.where(author: params[:login]).gte(committed_at: params[:days].to_i.days.ago).desc(:committed_at).all.group_by { |c| c.committed_at.to_date }
    @commit_dates    = @commits_by_date.keys.sort.reverse
  end

  def user_history
    params[:days] ||= 7
    @contributor      = Contributor.find_by(login: params[:login])
    @title            = "@#{@contributor.login}'s History"
    @issues           = Issue.where(assignee: params[:login], state: 'closed').gte(closed_at: params[:days].to_i.days.ago).desc(:closed_at, :updated_at)
  end

  def redirect_to_user
    redirect_to "/~#{session[:github_login]}"
  end

  def milestone
    @title            = params[:title]
    @milestone        = Milestone.find_by(title: params[:title])
    @issues           = Issue.where(milestone: params[:title], state: 'open').all.to_a
    @issues           += Issue.closed_today.where(milestone: params[:title]).all.to_a
    @recently_closed_issues = @milestone.issues.closed_today.desc(:closed_at)
    @recent_commits   = @milestone.commits.today.desc(:committed_at)
    @other_commits    = @milestone.commits.not_associated_to_issue.today.all

    render template: params[:view] == 'completed' ? 'boards/milestone_completed' : 'boards/milestone_todo'
  end

  def list_milestones
    @title = "All Milestones"
    @milestones = Milestone.open.all
  end

end