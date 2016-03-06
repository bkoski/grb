class GithubImporter

  # Set this to true to import all repos rather than only those with activity
  # in the past three days.
  attr_accessor :import_everything

  # Define a specific list of repos to crawl.
  attr_accessor :repos

  def run!
    # import_repos unless @repos.present?  # no need to fetch repos if we're being asked to import a specific one
    # import_commits
    import_issues
  end

  private

  def import_everything?
    @import_everything
  end

  def repos_to_crawl
    return @repos_to_crawl if @repos_to_crawl.present?

    if @repos.present?
      @repos_to_crawl = @repos
    elsif import_everything?
      @repos_to_crawl = Repo.asc(:name).all 
    else
      @repos_to_crawl = Repo.gte(last_activity_at: 3.days.ago).asc(:name)
    end
  end

  def import_repos
    last_scrape_time = ScrapeLog.last_scrape_time(:repo_list)
    return if !import_everything? && last_scrape_time.present? && last_scrape_time >= 15.minutes.ago

    puts "Importing repo list..."

    all_repos = Github.repos.list org: 'newsdev', auto_pagination: true
    all_repos.each do |repo_data|
      local_repo = Repo.find_or_create_by(name: repo_data.name)

      last_pushed_at = DateTime.parse(repo_data.pushed_at) 
      local_repo.last_activity_at = last_pushed_at if local_repo.last_activity_at.nil? || last_pushed_at > local_repo.last_activity_at
      local_repo.default_branch   = repo_data.default_branch
      local_repo.url              = repo_data.html_url

      if import_everything? || local_repo.last_activity_at >= 24.hours.ago
        puts "\timporting branches for #{repo_data.name}..."
        active_branches = Github.repos.branches('newsdev', repo_data.name).map(&:name)
        local_repo.active_branches = active_branches.select do |branch_name|
          branch_meta = Github.repos.branch('newsdev', repo_data.name, branch_name)
          last_touched = Date.parse(branch_meta.commit.commit.author.date)
          import_everything? || last_touched >= 1.week.ago
        end
      else
        local_repo.active_branches = []
      end

      local_repo.save!
    end

    ScrapeLog.record!(:repo_list)
  end

  def import_commits
    repos_to_crawl.each do |repo|
      puts "Importing commits for #{repo.name}:"

      repo.active_branches.each do |branch_name|
        puts "\ton #{branch_name} branch..."
        all_commits = Github.repos.commits.list 'newsdev', repo.name, since: 24.hours.ago, sha: branch_name

        all_commits.each do |commit_data|
          c = repo.commits.find_or_create_by(sha: commit_data.sha)

          c.author_name  = commit_data.author ? commit_data.author.login : commit_data.commit.author.email
          c.url          = commit_data.html_url
          c.message      = commit_data.commit.message
          c.branch       = branch_name
          c.committed_at = DateTime.parse(commit_data.commit.author.date)
          c.save!

          repo.last_activity_at = c.committed_at if c.committed_at > repo.last_activity_at
          repo.save! 
        end
      end
    end
  end

  def import_issues
    [OpenStruct.new(name: 'attribute')].each do |repo|
      puts "Importing issues for #{repo.name}..."

      list_query = {
        user: 'newsdev',
        repo: repo.name,
        state: 'all',
        auto_pagination: true
      }
      list_query[:since] = 3.hours.ago.utc.iso8601 unless import_everything?

      issues = Github.issues.list(list_query).to_a

      issues.each do |issue_data|
        i = Issue.find_or_initialize_by(github_id: issue_data.id)

        i.repo_name = repo.name
        i.number    = issue_data.number
        i.url       = issue_data.html_url
        i.state     = issue_data.state
        i.title     = issue_data.title
        i.assignee  = issue_data.assignee.try(:login)
        
        i.milestone = issue_data.milestone.try(:title)
        i.milestone_github_id = issue_data.milestone.try(:id)

        if i.milestone.present? 
          m = Milestone.find_or_initialize_by(github_id: i.milestone_github_id)
          m.update_attributes!(state: issue_data.milestone.state,
                               title: issue_data.milestone.title,
                              description: issue_data.milestone.description)
        end


        i.opened_at = DateTime.parse(issue_data.created_at)

        if i.assignee.present? && !Contributor.where(login: i.assignee).exists?
          Contributor.create!(login: i.assignee, avatar_url: issue_data.assignee.avatar_url)
        end

        # repo.update_attributes!(last_activity_at: i.opened_at) if i.opened_at > repo.last_activity_at 

        if issue_data.closed_at.present?
          i.closed_at = DateTime.parse(issue_data.closed_at)
          i.closed_by = Github.issues.get('newsdev', repo.name, issue_data.number).try(:closed_by).try(:login) if i.closed_by.blank?

          # repo.update_attributes!(last_activity_at: i.closed_at) if i.closed_at > repo.last_activity_at
        else
          i.closed_at = nil
          i.closed_by = nil
        end

        i.save!
      end
    end
  end

end