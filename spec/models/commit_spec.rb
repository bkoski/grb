require 'rails_helper'

RSpec.describe Commit, type: :model do

  describe "ingest" do
    before do
      @commit_data = {

      }
    end

    it "updates the Milestone's contributor list when there is an assignee" do
      @issue_data.milestone = { title: 'Test Milestone' }
      
      milestone = Milestone.create!(title: 'Test Milestone')
      Commit.ingest(@commit_data)
    
      milestone.reload
      milestone.contributors.should == ['test-user']
    end

  end

end
