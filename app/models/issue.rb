class Issue
  include Mongoid::Document
  include Mongoid::Timestamps
  include SortOrder

  # belongs_to :repo, index: true

  field :repo_name, type: String
  field :number,    type: Integer
  field :github_id, type: Integer
  field :url, type: String
  field :state, type: String
  field :title, type: String
  field :assignee, type: String
  field :closed_by, type: String
  field :milestone, type: String
  field :milestone_github_id, type: Integer
  field :closed_at, type: DateTime
  field :opened_at, type: DateTime
  field :labels, type: Array, default: []

  scope :opened_today, -> { gte(opened_at: 24.hours.ago) }
  scope :closed_today, -> { gte(closed_at: 24.hours.ago) }

  scope :open, -> { where(state: 'open') }
  scope :closed, -> { where(state: 'closed') }
  scope :unassigned, -> { where(assignee: nil) }

  index({ repo_name: 1, github_id: 1 }, { unique: true, drop_dups: true })

  index({ milestone: 1, state: 1 })

  index({ assignee: 1, state: 1 })
  index({ assignee: 1, closed_at: 1 })

  index({ opened_at: 1 })
  index({ closed_at: 1 })

  after_save :broadcast_to_pusher

  def sort_ts
    closed_at || opened_at || updated_at
  end

  def in_progress?
    labels.include?('in-progress')
  end

  def priority?
    labels.include?('priority')
  end

  def to_broadcast_h
    {
      _id: _id.to_s,
      assignee: assignee,
      repo_name: repo_name,
      state: state,
      title: title,
      milestone: milestone,
      in_progress: in_progress?,
      priority: priority?,
      url: url
    }
  end

  def self.ingest(repo_name, issue_data)
    i = Issue.find_or_initialize_by(github_id: issue_data.id)

    puts "Importing #{repo_name} ##{issue_data.number}."

    i.repo_name = repo_name
    i.number    = issue_data.number
    i.url       = issue_data.html_url
    i.state     = issue_data.state
    i.title     = issue_data.title
    i.assignee  = issue_data.assignee.try(:login)
    
    i.milestone = issue_data.milestone.try(:title)
    i.milestone_github_id = issue_data.milestone.try(:id)

    if i.milestone.present? 
      m = Milestone.find_or_initialize_by(github_id: i.milestone_github_id)
      m.state = issue_data.milestone.state
      m.title = issue_data.milestone.title
      m.description = issue_data.milestone.descripton
      m.repos       |= [i.repo_name]
      m.save!
    end

    i.opened_at = DateTime.parse(issue_data.created_at)
    i.closed_at = DateTime.parse(issue_data.closed_at) rescue nil

    if i.assignee.present? && !Contributor.where(login: i.assignee).exists?
      Contributor.create!(login: i.assignee, avatar_url: issue_data.assignee.avatar_url)
    end

    # repo.update_attributes!(last_activity_at: i.opened_at) if i.opened_at > repo.last_activity_at 

    i.save!
  end

  def set_status!(status)
    case status
    when 'closed'
      # GH update: state closed, - label in progress
      self.state  = 'closed'
      self.labels.delete('in-progress')
    when 'active'
      # GH update: state open + label in progress
      self.state = 'open'
      self.labels |= ['in-progress']
    when 'inactive'
      # GH update: state open, - label in progress
      self.state  = 'open'
      self.labels.delete('in-progress')
    when 'priority'
      self.state = 'open'
      self.labels |= ['priority']
    when 'normal_priority'
      self.labels -= ['priority']
    else
      raise ArgumentError, "Unknown status '#{status}'!"
    end

    self.save!
  end

  def broadcast_to_pusher
    $pusher.trigger('grb', 'update', self.to_broadcast_h.to_json)
  end

end