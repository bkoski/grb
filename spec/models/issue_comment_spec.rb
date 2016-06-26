require 'rails_helper'

RSpec.describe IssueComment, type: :model do

  describe "commit reference parsing" do

    before do
      @issue  = Issue.create!(repo_name: 'test-repo1', github_id: '2345')
      @commit = Commit.create!(sha: 'b23bf19f98ac0b8d6bf32f1db5d19ce25d16548d', repo_name: 'test-repo1', message: 'Test commit')
      Issue.any_instance.stubs(:add_label)


      @comment_data = Hashie::Mash.new({
        repository: { name: 'test-repo1' },
        issue:      { id:   '2345' },
        comment:    {
          created_at: DateTime.now.iso8601,
          body:  @commit.sha,
          user: { login: 'test-user' },
          html_url: 'http://github.com/comment/2345'
        }
      })
    end

    it "associates the referenced commit to the issue" do
      IssueComment.ingest(@comment_data)
      @issue.reload
      @issue.commits.should == [@commit]
    end

    it "associates the reference commit to the issue, even if the reference is at the end of the comment body" do
      @comment_data.comment.body = "Fixed in: #{@commit.sha}"
      IssueComment.ingest(@comment_data)
      @issue.reload
      @issue.commits.should == [@commit]
    end

    it "associates the reference commit to the issue, even if the reference is at the beginning of the comment body" do
      @comment_data.comment.body = "#{@commit.sha} has this"
      IssueComment.ingest(@comment_data)
      @issue.reload
      @issue.commits.should == [@commit]
    end

    it "associates the reference commit to the issue, even if the reference is in the middle of the comment body" do
      @comment_data.comment.body = "This commit #{@commit.sha} has the update"
      IssueComment.ingest(@comment_data)
      @issue.reload
      @issue.commits.should == [@commit]
    end

    it "adds the in-progress label to the issue, if the issue is open and the milestone is active" do
      @issue.update_attributes!(state: 'open')
      Issue.any_instance.stubs(:milestone_active?).returns(true)
      Issue.any_instance.expects(:add_label).with('in-progress')
      IssueComment.ingest(@comment_data)
    end

    it "does not add an in-progress label to the issue if the issue is closed" do
      @issue.update_attributes!(state: 'closed')
      Issue.any_instance.stubs(:milestone_active?).returns(true)
      Issue.any_instance.expects(:add_label).never
      IssueComment.ingest(@comment_data)
    end
  end

end
