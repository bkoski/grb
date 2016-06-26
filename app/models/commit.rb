class Commit
  include Mongoid::Document
  include ActionView::Helpers::TextHelper

  field :sha,       type: String
  field :repo_name, type: String
  field :branch,    type: String
  field :message,   type: String
  field :author,    type: String
  field :url,       type: String
  field :committed_at, type: DateTime

  scope :today, -> { gte(committed_at: 24.hours.ago) }
  scope :this_week, -> { gte(committed_at: 1.week.ago) }
  scope :not_associated_to_issue, -> { where(:issue_ids.with_size => 0) }

  has_and_belongs_to_many :issues

  index({ repo_name: 1, committed_at: -1 })
  index({ repo_name: 1, sha: 1 }, { unique: true })

  after_save :check_for_issue_associations

  def self.import(repo_name: nil, branch: nil, commit_data: nil)
    commit = self.find_or_initialize_by(repo_name: repo_name, sha: commit_data.id || commit_data.sha)
    commit.branch = branch

    if commit_data.commit  # we're importing a record from the API
      commit.url          = commit_data.html_url
      commit.message      = commit_data.commit.message
      commit.author       = commit_data.author ? commit_data.author.login : commit_data.commit.author.email
      commit.committed_at = DateTime.parse(commit_data.commit.author.date)

    else # we're importing a webhook
      commit.url     = commit_data.url
      commit.message = commit_data.message
      commit.author  = commit_data.author.username || commit_data.author.name
      commit.committed_at = DateTime.parse(commit_data.timestamp)

    end

    commit.save!

    commit
  end

  def self.scrape_for_repo(repo_name: repo_name, branch: 'master', since: 24.years.ago)
    all_commits = Github.repos.commits.list ENV['DEFAULT_GITHUB_ORG'], repo_name, since: since, sha: branch
    all_commits.each { |c| import(repo_name: repo_name, branch: branch, commit_data: c) }
  end

  def to_broadcast_h
    { 
      url: url,
      message: truncate(message, length: 80, separator: ' '),
      author: author
    }
  end

  private
  def check_for_issue_associations
    self.issues = []
    message.scan(/#(\d+)[^\d]?/) do |issue_number_match|
      referenced_issue = Issue.where(repo_name: repo_name, number: issue_number_match.first).first
      next if referenced_issue.nil?

      self.issues << referenced_issue
      referenced_issue.add_label('in-progress') if referenced_issue.milestone_active? && referenced_issue.open?

      if referenced_issue.milestone.present?
        milestone = Milestone.find_by(name: referenced_issue.milestone)
        milestone.contributors |= [self.author]
        milestone.save!
      end
    end
  end

end
