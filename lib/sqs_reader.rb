class SqsReader

  def self.run
    poller = Aws::SQS::QueuePoller.new(ENV['SQS_QUEUE_URL'])

    poller.poll do |msg|
      sns_event    = JSON.parse(msg.body)
      github_event = Hashie::Mash.new JSON.parse(sns_event['Message'])

      puts "Event: #{github_event.keys.sort.join(',')}"

      if github_event.issue
        issue = Issue.ingest(github_event.repository.name, github_event.issue)
        puts "Ingested #{github_event.action} for #{github_event.repository.full_name}# #{github_event.issue.number}."

      elsif github_event.commits && github_event.ref.to_s.match("refs/heads") # push event
        github_event.commits.each do |c|
          Commit.import(repo_name: github_event.repository.name,
                        branch: github_event.ref.match("refs/heads/(.+)")[1],
                        commit_data: c)
        end

      end
    end
  end

end