class GithubImporter

  attr_accessor :backfill_for

  def initialize
    @backfill_for = 1.day
  end

  def run!
    import_commits
  end

  private

  def github
    Github.new(oauth_token: Thread.current[:github_token])
  end

  def all_repos
    repos = github.repos.list org: ENV['DEFAULT_GITHUB_ORG'], auto_pagination: true
    repos.select { |r| DateTime.parse(r.pushed_at) >= backfill_for.ago }
  end

  def active_branches(repo)
    branches = github.repos.branches(ENV['DEFAULT_GITHUB_ORG'], repo.name).map(&:name)
    branches.select do |branch_name|
      branch_meta  = github.repos.branch(ENV['DEFAULT_GITHUB_ORG'], repo.name, branch_name)
      last_touched = Date.parse(branch_meta.commit.commit.author.date)
      last_touched >= backfill_for.ago
    end
  end

  def import_commits
    all_repos.each do |repo|
      puts "Importing commits for #{repo.name}:"

      active_branches(repo).each do |branch_name|
        puts "\ton #{branch_name} branch..."
        all_commits = github.repos.commits.list ENV['DEFAULT_GITHUB_ORG'], repo.name, since: backfill_for.ago, sha: branch_name

        all_commits.each do |commit_data|
          Commit.import(repo_name: repo.name, branch: branch_name, commit_data: commit_data)
        end
      end
    end
  end

end
