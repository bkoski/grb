# This scrapes the "All Issues" endpoint for the Github organization,
# since there are some issue edits that still do not broadcast webhooks:
# most notably, when the milestone association on an issue is changed.
#
# If this is eventually supported, this file can be safely removed.
class IssueScrape
  include Mongoid::Document
  include Mongoid::Timestamps

  field :last_update_time, type: String
  field :etag,             type: String
  field :rate_limit_remaining, type: Integer

  index({ created_at: 1 }, { expire_after_seconds: 1.week })

  def self.run
    most_recent_scrape = self.desc(:created_at).first

    connection_opts = {}
    req_params = {
      org: ENV['DEFAULT_GITHUB_ORG'],
      filter: 'all',
      state: 'all',
      auto_pagination: true
    }

    if most_recent_scrape
      req_params[:since]        = most_recent_scrape.last_update_time
      connection_opts[:headers] = { 'If-None-Match' => most_recent_scrape.etag }
    else
      req_params[:since] = 3.hours.ago.utc.iso8601
    end

    github = Github.new(connection_options: connection_opts)
    issues = github.issues.list(req_params)

    status = issues.response.status
    etag   = issues.response.headers['etag']
    rate_limit_remaining = issues.response.headers['x-ratelimit-remaining']

    puts "Response: #{status}, #{rate_limit_remaining} reqs remaining."

    return if status != 200

    issues.each do |issue_data|
      Issue.ingest(issue_data.repository.name, issue_data)
    end

    self.create!(last_update_time: issues.first.updated_at,
                 etag: etag,
                 rate_limit_remaining: rate_limit_remaining)
  end

end
