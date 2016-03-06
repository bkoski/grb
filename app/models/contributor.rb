class Contributor
  include Mongoid::Document

  field :login, type: String
  field :avatar_url, type: String
  field :full_name, type: String

end