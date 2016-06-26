require 'rails_helper'

RSpec.describe Issue, type: :model do

  describe "ingest" do

    before do
      @issue_data = Hashie::Mash.new({
        id: '2345',
        number: 1,
        html_url: 'http://github.com/issues/1',
        state: 'open',
        title: 'Test Issue',
        assignee: { login: 'test-user' },
        labels: [],
        created_at: DateTime.now.iso8601
      })
    end

    describe "when an issue is being closed" do
      before do
        @issue_data.state = 'closed'
        @issue_data.closed_at = DateTime.now.iso8601
      end

      it "strips in-progress and priority tags" do
        @issue_data.labels = [ { name: 'in-progress' }, { name: 'priority' }, { name: 'bug' } ]
        Issue.any_instance.expects(:remove_label).with('in-progress')
        Issue.any_instance.expects(:remove_label).with('priority')
        Issue.any_instance.expects(:remove_label).with('bug').never
        Issue.ingest('test-repo', @issue_data)
      end
    end
    
  end

end
