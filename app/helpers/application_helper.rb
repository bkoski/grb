module ApplicationHelper

  def slugify(str)
    str.downcase.gsub(/\W+/, '-').gsub(/^-|-$/,'')
  end

end
