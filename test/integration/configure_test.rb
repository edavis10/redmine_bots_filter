require 'test_helper'

class ConfigureTest < ActionController::IntegrationTest

  def setup
    configure_plugin
    Role.anonymous.update_attribute(:permissions, Redmine::AccessControl.permissions.collect(&:name)) # All permissions for anon
    @project = Project.generate!(:is_public => true, :identifier => 'bots').reload
    WikiPage.generate!(:wiki => @project.wiki, :title => 'Start', :content => WikiContent.new(:text => 'Hello'))
    @repository = Repository::Subversion.create(:url => "file:///#{ActiveSupport::TestCase.repository_path('subversion')}", :project => @project) do |repo|
      repo.type = 'Subversion'
    end

    @issue = Issue.generate_for_project!(@project)

    @user = User.generate!(:admin => true, :login => 'admin', :password => 'existing', :password_confirmation => 'existing')
    login_as('admin')
  end

  should "have a configuration page" do
    click_link "Administration"
    assert_response :success

    click_link "Plugins"
    assert_response :success
    assert_equal "/admin/plugins", current_path

    click_link "Configure"
    assert_response :success
    assert_equal "/settings/plugin/redmine_bots_filter", current_path
  end
  
  should "allow configuring the bots list" do
    click_link "Administration"
    click_link "Plugins"
    click_link "Configure"

    assert_select "#bots", :text => /googlebot/

    fill_in "Bots", :with => "firefox\nsafari, chrome"

    click_button "Apply"
    assert_response :success

    assert_equal "firefox\nsafari, chrome", Setting.plugin_redmine_bots_filter["bots"]

  end

  context "with a customized bots list" do
    setup do
      reconfigure_plugin("bots" => "firefox\nsafari, chrome")
    end
    
    should_block_bot('firefox', '/activity')
    should_block_bot('safari', '/activity')
    should_block_bot('chrome', '/activity')
  end

  context "with a nil list" do
    setup do
      reconfigure_plugin("bots" => nil)
    end

    should_not_block_bot('firefox', '/activity')
    should_not_block_bot('googlebot', '/activity')
  end

  context "with an empty list" do
    setup do
      reconfigure_plugin("bots" => '')
    end

    should_not_block_bot('firefox', '/activity')
    should_not_block_bot('googlebot', '/activity')
  end

end
