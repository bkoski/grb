namespace :github do

  desc "Start the daemon to listen to SQS messages"
  task :sqs_import => [:environment, :set_service_token] do
    SqsReader.run
  end

  desc "pass DAYS_TO_BACKFILL to retroactively re-import issues"
  task :backfill_issues => [:environment, :set_service_token] do 
    IssueScrape.run(backfill_for: ENV['DAYS_TO_BACKFILL'].to_i.days)
  end
  
  desc "pass DAYS_TO_BACKFILL to retroactively re-import commits"
  task :backfill_commits => [:environment, :set_service_token] do
    importer = GithubImporter.new
    importer.backfill_for = ENV['DAYS_TO_BACKFILL'].to_i.days
    importer.run!
  end

  desc "Start an IssueScrape loop to capture milestone changes"
  task :scrape_issues => [:environment, :set_service_token] do
    loop { IssueScrape.run; sleep 15; }
  end

  task :set_service_token do
    Thread.current[:github_token] = ENV['GITHUB_TOKEN']
  end
  
end