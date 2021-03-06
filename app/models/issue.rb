class Issue
  include Mongoid::Document
  include Mongoid::Timestamps
  include SortOrder

  # belongs_to :repo, index: true

  has_and_belongs_to_many :commits, order: :committed_at.desc
  has_many :issue_comments

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

  def open?
    state == 'open'
  end

  def milestone_active?
    Milestone.where(title: milestone).first.try(:active?)
  end

  def in_progress?
    labels.include?('in-progress')
  end

  def priority?
    labels.include?('priority')
  end

  def needs_review?
    labels.include?('for-review')
  end

  def to_broadcast_h
    {
      _id: _id.to_s,
      assignee: assignee,
      repo_name: repo_name,
      state: state,
      title: title,
      number: number,
      milestone: milestone,
      in_progress: in_progress?,
      priority: priority?,
      for_review: needs_review?,
      url: url,
      sort_order: sort_order,
      commits: commits.map(&:to_broadcast_h)
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

    i.labels    = issue_data.labels.map { |label| label.name }
    
    i.milestone = issue_data.milestone.try(:title)
    i.milestone_github_id = issue_data.milestone.try(:id)

    if i.milestone.present? 
      m = Milestone.find_or_initialize_by(title: i.milestone)
      m.state  = issue_data.milestone.state
      m.title  = issue_data.milestone.title
      m.description = issue_data.milestone.descripton

      m.numbers[i.repo_name]    = issue_data.milestone.number
      m.github_ids[i.repo_name] = issue_data.milestone.id
      
      m.repos        |= [i.repo_name]
      m.contributors |= [i.assignee] if i.assignee.present?
      
      m.save!
    end

    i.opened_at = DateTime.parse(issue_data.created_at)
    i.closed_at = DateTime.parse(issue_data.closed_at) rescue nil

    if i.assignee.present? && !Contributor.where(login: i.assignee).exists?
      Contributor.create!(login: i.assignee, avatar_url: issue_data.assignee.avatar_url)
    end

    ### Label automations ###

    # Only apply automations to milestones we're actively tracking in grb.
    if i.milestone_active?
      # remove in-progress and priority labels when an issue is closed
      i.remove_label('in-progress') if !i.open? && i.labels.include?('in-progress')
      i.remove_label('priority')    if !i.open? && i.labels.include?('priority')

      # toggle the for-review label on when issues are closed, remove it if they are re-opened
      i.remove_label('for-review') if i.open?  && i.state_changed?
      i.add_label('for-review')    if !i.open? && i.state_changed?
    end

    # repo.update_attributes!(last_activity_at: i.opened_at) if i.opened_at > repo.last_activity_at 

    i.save!
    i
  end

  def set_status!(status)
    case status
    when 'closed'
      set_issue_state('closed')
      remove_label('in-progress')
    when 'active'
      set_issue_state('open')
      add_label('in-progress')
    when 'inactive'
      set_issue_state('open')
      remove_label('in-progress')
    when 'priority'
      set_issue_state('open')
      add_label('priority')
    when 'normal_priority'
      set_issue_state('open')
      remove_label('priority')
    else
      raise ArgumentError, "Unknown status '#{status}'!"
    end

    self.save!
  end

  LABEL_COLORS = {
    'for-review' => '5319e7',
    'in-progress' => '009933',
    'priority' => 'cc0000',
    'test1' => 'ffff00'
  }

  def add_label(label_name)
    # Don't repeatedly call to add a label if it already exists
    return if self.labels.include?(label_name)

    labels = github.issues.labels.add(ENV['DEFAULT_GITHUB_ORG'], repo_name, number, label_name)

    target_color = LABEL_COLORS[label_name]
    if target_color && labels.first.color != target_color
      github.issues.labels.update(ENV['DEFAULT_GITHUB_ORG'], repo_name, label_name, name: label_name, color: target_color)
    end

    self.labels |= [label_name]
  end

  def remove_label(label_name)
    # Don't make unnecessary remove calls
    return unless self.labels.include?(label_name)

    begin
      github.issues.labels.remove(ENV['DEFAULT_GITHUB_ORG'], repo_name, number, label_name: label_name)
    rescue Github::Error::NotFound
      # Just ignore issues where we're trying to remove a label that doesn't exist in github for some reason.
    end

    self.labels -= [label_name]
  end

  def assign_to(new_assignee)
    self.assignee = new_assignee
    github.issues.edit(ENV['DEFAULT_GITHUB_ORG'], repo_name, number, assignee: new_assignee)
  end

  def set_issue_state(new_state)
    return if self.state == new_state
    self.state = new_state
    github.issues.edit(ENV['DEFAULT_GITHUB_ORG'], repo_name, number, state: new_state)
  end

  def broadcast_to_pusher
    $pusher.trigger('grb', 'update', self.to_broadcast_h.to_json)
  end

  private
  def github
    @github ||=  Github.new oauth_token: Thread.current[:github_token]
  end

end