require 'rails_helper'

RSpec.describe Issue, type: :model do

  describe "#add_label" do

    it "does not repeatedly call to add a label once it exists" do
      Github::Client::Issues::Labels.any_instance.expects(:add).once
      @issue = Issue.new(repo_name: 'test-repo')
      @issue.add_label('test-label')
      @issue.add_label('test-label')
    end

    it "updates the internal label state immediately" do
      Github::Client::Issues::Labels.any_instance.stubs(:add)

      @issue = Issue.new(repo_name: 'test-repo', labels: ['bug'])
      @issue.add_label('test-label')

      @issue.labels.should == ['bug','test-label']
    end

    it "defines the label color for the priority label, if it has not already been defined" do
      Github::Client::Issues::Labels.any_instance.stubs(:add).returns(Hashie::Mash.new({ color: '#111' }))
      Github::Client::Issues::Labels.any_instance.stubs(:update).with(anything, anything, 'priority', { name: 'priority', target_color: Issue::LABEL_COLORS['priority'] })

      @issue = Issue.new(repo_name: 'test-repo', labels: ['bug'])
      @issue.add_label('test-label')
    end

    it "skips the call to define label color if it is already set" do
      Github::Client::Issues::Labels.any_instance.stubs(:add).returns(Hashie::Mash.new({ color: Issue::LABEL_COLORS['priority'] }))
      Github::Client::Issues::Labels.any_instance.stubs(:update).never

      @issue = Issue.new(repo_name: 'test-repo', labels: ['bug'])
      @issue.add_label('test-label')
    end

  end

  describe "#remove_label" do
    it "does not repeatedly call to remove a label" do
      Github::Client::Issues::Labels.any_instance.expects(:remove).once
      @issue = Issue.new(repo_name: 'test-repo', labels: ['test-label'])
      @issue.remove_label('test-label')
      @issue.remove_label('test-label')
    end

    it "updates the internal label state immediately" do
      Github::Client::Issues::Labels.any_instance.stubs(:remove)

      @issue = Issue.new(repo_name: 'test-repo', labels: ['bug'])
      @issue.remove_label('test-label')

      @issue.labels.should == ['bug']
    end

    it "silently ignores issues where the label no longer exists on the issue" do
      Github::Client::Issues::Labels.any_instance.stubs(:remove).raises(Github::Error::NotFound.new(response_headers: {}, body: nil, status: 404))

      @issue = Issue.new(repo_name: 'test-repo', labels: ['test-label'])
      expect { @issue.remove_label('test-label') }.to_not raise_error
    end
  end

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

    it "updates the Milestone's contributor list when there is an assignee" do
      @issue_data.milestone = { title: 'Test Milestone' }
      
      milestone = Milestone.create!(title: 'Test Milestone')
      Issue.ingest('test-repo', @issue_data)
    
      milestone.reload
      milestone.contributors.should == ['test-user']
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
