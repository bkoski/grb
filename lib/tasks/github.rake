namespace :github do

  task :sqs_import => [:environment, :set_service_token] do
    SqsReader.run
  end

  task :scrape_issues => [:environment, :set_service_token] do
    loop { IssueScrape.run; sleep 15; }
  end

  task :set_service_token do
    Thread.current[:github_token] = ENV['GITHUB_TOKEN']
  end
  
end