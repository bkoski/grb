class IssueComment
  include Mongoid::Document

  belongs_to :issue

  field :github_id, type: Integer
  field :issue_github_id, type: Integer

  field :repo_name, type: String
  field :added_at,  type: DateTime
  field :body,      type: String
  field :commenter, type: String
  field :url,       type: String

  before_save :check_issue_association, :check_for_referenced_commits

  def self.ingest(github_data)
    comment = IssueComment.find_or_initialize_by(github_id: github_data.comment.id)

    comment.repo_name       = github_data.repository.name
    comment.issue_github_id = github_data.issue.id
    comment.added_at        = DateTime.parse(github_data.comment.created_at)
    comment.body            = github_data.comment.body
    comment.commenter       = github_data.comment.user.login
    comment.url             = github_data.comment.html_url

    comment.save!
    comment
  end

  private
  def check_issue_association
    self.issue ||= Issue.find_by(github_id: issue_github_id)
  end

  def check_for_referenced_commits
    sha_regexp = /\b[0-9a-f]{40}\b/
    
    body.scan(sha_regexp).each do |referenced_sha|
      Commit.find_or_create_by(repo_name: repo_name, sha: referenced_sha).issues << issue
    end

    if body.match(sha_regexp) && issue && issue.milestone_active? && issue.open?
      issue.add_label('in-progress')
    end
  end

end
