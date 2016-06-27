require 'rails_helper'

RSpec.describe Commit, type: :model do

  describe "ingest" do
    before do
      @commit_data = Hashie::Mash.new({
        sha: '1234abc',
        author: { username: 'test-user' },
        timestamp: DateTime.now.iso8601,
        message: '[Fixes #10] test message'
      })
    end

    it "updates the Milestone's contributor list when there is an assignee, and the commit is linked to an issue" do      
      milestone = Milestone.create!(title: 'Test Milestone')
      issue = Issue.create!(repo_name: 'test-repo', number: 10, milestone: 'Test Milestone')
      Commit.import(repo_name: 'test-repo', branch: 'master', commit_data: @commit_data)
    
      milestone.reload
      milestone.contributors.should == ['test-user']
    end

  end

end
