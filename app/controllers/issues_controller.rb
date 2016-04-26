class IssuesController < ApplicationController

  def update_sort_order
    target_obj = Issue.find(params[:target_id])
    target_obj.relative_sort(params[:anchor], params[:anchor_id])
    head 200
  end

  def create
    # Validate input
    error_messages = []

    error_messages << "A title must be provided." if params[:title].blank?
    error_messages << "A repo must be selected."  if params[:repo_name].blank?

    if error_messages.length > 0
      render(status: 400, text: error_messages.join(' ')) and return
    end

    # Build up request body
    request_opts = {
      user:  ENV['DEFAULT_GITHUB_ORG'],
      repo:  params[:repo_name],
      milestone: params[:milestone_number],
      title: params[:title],
    }

    [:body, :assignee].each do |optional_field|
      request_opts[optional_field] = params[optional_field] if params[optional_field].present?
    end

    # Create issue in Github.
    github = Github.new oauth_token: Thread.current[:github_token]
    new_issue_data = github.issues.create(request_opts)

    # Ingest the data into local db so that it's immediately available.
    new_issue = Issue.ingest(params[:repo_name], new_issue_data)

    # Apply sort as requested
    if params[:sort] == 'top'
      top_issue = Issue.where(milestone_github_id: params[:milestone_github_id]).open.asc(:sort_order).first
      new_issue.relative_sort('before', top_issue)
    end

    head 200
  end

  def update
    @issue = Issue.find(params[:id])
    @issue.assign_to(params[:assignee]) if params[:assignee]
    @issue.set_status!(params[:status]) if params[:status]
    head 200
  end

end