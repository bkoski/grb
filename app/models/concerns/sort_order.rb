module SortOrder
  extend ActiveSupport::Concern

  included do
    field :sort_order, type: Float
    default_scope ->{ asc(:sort_order) }
    before_create :set_default_sort
    index({ sort_order: 1 })
  end

  class_methods do
    def reset_sort!
      self.all.each_with_index { |obj,idx| puts idx; obj.update_attributes!(sort_order: idx) }
    end
  end

  def relative_sort(anchor, object_id)
    sort_fn = nil
    case anchor
    when 'before'
      sort_fn = ->(base_sort_order) { self.class.lte(sort_order: base_sort_order).limit(2) }
    when 'after'
      sort_fn = ->(base_sort_order) { self.class.gte(sort_order: base_sort_order).limit(2) }
    else
      raise ArgumentError, "Invalid anchor value '#{anchor}'!"
    end

    base_sort_order     = self.class.where(_id: object_id).pluck(:sort_order).first
    nearest_sort_orders = sort_fn.call(base_sort_order).pluck(:sort_order).sort

    if nearest_sort_orders.length == 2
      diff = (nearest_sort_orders.last - nearest_sort_orders.first) / 2
    else
      diff = 0.5
    end

    if anchor == 'before'
      new_sort_order = base_sort_order - diff
    elsif anchor == 'after'
      new_sort_order = base_sort_order + diff
    end

    update_attributes!(sort_order: new_sort_order)
  end

  private
  def set_default_sort
    self.sort_order = self.class.max(:sort_order)
  end

end