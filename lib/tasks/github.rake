namespace :github do

  task :sqs_import => :environment do
    SqsReader.run
  end

  task :import => :environment do
    puts "Starting import at #{Time.now}..."
    start_time = Time.now

    importer = GithubImporter.new
    importer.import_everything = true if ENV['ALL'].present?
    importer.run!

    duration = Time.now - start_time
    puts "Finished in #{'%0.2f' %  duration}s."
  end
end