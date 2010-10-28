# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require "webrat"

Webrat.configure do |config|
  config.mode = :rails
end

def User.add_to_project(user, project, role)
  Member.generate!(:principal => user, :project => project, :roles => [role])
end

module RedmineWebratHelper
  def login_as(user="existing", password="existing")
    visit "/login"
    fill_in 'Login', :with => user
    fill_in 'Password', :with => password
    click_button 'login'
    assert_response :success
    assert User.current.logged?
  end

  def visit_project(project)
    visit '/'
    assert_response :success

    click_link 'Projects'
    assert_response :success

    click_link project.name
    assert_response :success
  end

  def visit_issue_page(issue)
    visit '/issues/' + issue.id.to_s
  end

  def visit_issue_bulk_edit_page(issues)
    visit url_for(:controller => 'issues', :action => 'bulk_edit', :ids => issues.collect(&:id))
  end

  # Cleanup current_url to remove the host; sometimes it's present, sometimes it's not
  def current_path
    return nil if current_url.nil?
    return current_url.gsub("http://www.example.com","")
  end

end

class ActionController::IntegrationTest
  include RedmineWebratHelper
end

class ActiveSupport::TestCase
   def self.should_block_bot(user_agent, path)
    should "block #{user_agent} from #{path}" do
      header "User-Agent", user_agent
      visit path

      assert_response :forbidden
      assert_equal "Bots are not allowed to view this page.", response.body
    end

  end

  def self.should_not_block_bot(user_agent, path)
    should "not block #{user_agent} from #{path}" do
      header "User-Agent", user_agent
      visit path

      assert_response :success
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

  def self.should_not_block_bots(&path_proc)
    path = path_proc.call

    should_not_block_bot('googlebot', path)
    should_not_block_bot('yahoo! slurp', path)
    should_not_block_bot('msnbot', path)
    should_not_block_bot('baiduspider', path)
    should_not_block_bot('yandex', path)
    should_not_block_bot('spider', path)
    should_not_block_bot('robot', path)
  end

  def self.should_not_block_browsers(&path_proc)
    path = path_proc.call

    should "not block browsers from '#{path}'" do
      visit path
      assert_response :success
    end
  end


 
  def assert_forbidden
    assert_response :forbidden
    assert_template 'common/403'
  end

  def configure_plugin(configuration_change={})
    Setting.plugin_redmine_bots_filter = {
      'bots' => "googlebot,yahoo! slurp,msnbot,baiduspider,yandex,spider\nrobot"
    }.merge(configuration_change)
  end

  def reconfigure_plugin(configuration_change)
    Setting['plugin_redmine_bots_filter'] = Setting['plugin_redmine_bots_filter'].merge(configuration_change)
  end
end
