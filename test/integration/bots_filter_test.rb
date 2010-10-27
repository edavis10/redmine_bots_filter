require 'test_helper'

class BotsFilterTest < ActionController::IntegrationTest

  def self.should_block_bot(user_agent, path)
    should "block #{user_agent} from #{path}" do
      header "User-Agent", user_agent
      visit path
      
      assert_response :forbidden
      assert_equal "Bots are not allowed to view this page.", response.body
    end

  end
  
  def self.should_block_bots(&path_proc)
    path = path_proc.call

    should_block_bot('googlebot', path)
    should_block_bot('yahoo! slurp', path)
    should_block_bot('msnbot', path)
    should_block_bot('baiduspider', path)
    should_block_bot('yandex', path)
    should_block_bot('spider', path)
    should_block_bot('robot', path)
  end

  def self.should_not_block_browsers(&path_proc)
    path = path_proc.call

    should "not block browsers" do
      visit path
      assert_response :success
    end
  end

  def setup
    @project = Project.generate!(:is_public => true, :identifier => 'bots').reload
    @repository = Repository::Subversion.create(:url => "file:///#{ActiveSupport::TestCase.repository_path('subversion')}", :project => @project) do |repo|
      repo.type = 'Subversion'
    end
  end
  
  context "repositories" do
    should_block_bots { "/projects/bots/repository" }
    should_not_block_browsers { "/projects/bots/repository" }
  end

  context "gantt chart" do
    should_block_bots { "/issues/gantt" }
    should_block_bots { "/projects/bots/issues/gantt" }

    should_not_block_browsers { "/issues/gantt" }
    should_not_block_browsers { "/projects/bots/issues/gantt" }
  end
  
end

