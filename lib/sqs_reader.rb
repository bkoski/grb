class SqsReader

  def self.run
    poller = Aws::SQS::QueuePoller.new(ENV['SQS_QUEUE_URL'])

    poller.poll do |msg|
      sns_event    = JSON.parse(msg.body)
      github_event = Hashie::Mash.new JSON.parse(sns_event['Message'])

      puts "Event: #{github_event.keys.sort.join(',')}"
      # Right now, we only listen to issue events:
      if github_event.issue
        issue = Issue.ingest(github_event.repository.name, github_event.issue)
        puts "Ingested #{github_event.action} for #{github_event.repository.full_name}# #{github_event.issue.number}."
      end
    end
  end

end