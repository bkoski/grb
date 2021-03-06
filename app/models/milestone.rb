class Milestone
  include Mongoid::Document
  include Mongoid::Timestamps
  include SortOrder

  field :title,       type: String
  field :state,       type: String
  field :description, type: String
  field :active, type: Boolean, default: false

  field :repos,       type: Array, default: []
  field :contributors, type: Array, default: []

  # THese attrs are stored as a repo_name => value hash
  field :github_ids,  type: Hash, default: {}
  field :numbers,     type: Hash, default: {}

  scope :open, -> { where(state: 'open') }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  before_create :default_sort_order

  index({ title: 1 }, unique: true)

  def set_status!(status)
    case status
    when 'active'
      update_attributes!(active: true)
      # ensure open on github
    when 'inactive'
      update_attributes!(active: false)
      # no change to github
    when 'closed'
      update_attributes!(active: false)
      # ensure closed on github
    end
  end

  def commits
    Commit.in(repo_name: repos).all
  end

  def issues
    Issue.where(milestone: self.title).all
  end

  #### TODO: rename method

  private
  def default_sort_order
    self.sort_order = Milestone.max(:sort_order).to_i + 1
  end

end