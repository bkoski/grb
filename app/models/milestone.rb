class Milestone
  include Mongoid::Document
  include Mongoid::Timestamps
  include SortOrder
  
  field :github_id,   type: Integer
  field :title,       type: String
  field :state,       type: String
  field :description, type: String
  field :repos, type: Array, default: []

  ### TODO: allow reference to multiple gh milestones

  field :active, type: Boolean, default: false

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  before_create :default_sort_order

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

  #### TODO: rename method

  private
  def default_sort_order
    self.sort_order = Milestone.maximum(:sort_order).to_i + 1
  end

end