begin
  # Rails >= 2.3 (Redmine 0.9)
  require 'application_controller'
rescue LoadError
  # Rails < 2.3 (Redmine 0.8.x)
  # Quick and dirty fix for 0.8.7 (make sure that session_store.rb gets loaded before ApplicationController)
  session_store = "#{RAILS_ROOT}/config/initializers/session_store.rb"
  if File.exist?(session_store)
    require session_store
  end
  require 'application'
end

module RedmineBotsFilter
  
  protected
  
  def bots_filter
    if bot_request?
      if !params[:format].blank? ||
           (controller_name == 'repositories') ||
           (controller_name == 'attachments') ||
           (controller_name == 'issues' && !params[:query_id].blank?) ||
           (controller_name == 'gantts') ||
           (controller_name == 'calendars') ||
           (controller_name == 'activities') ||
           (controller_name == 'wiki' && (action_name == 'history' || !params[:version].blank?))
           
        render :text => 'Bots are not allowed to view this page.', :layout => false, :status => 403
        return false
      end
    end
    true
  end
  
  def bots_to_filter
    bots = Setting.plugin_redmine_bots_filter["bots"]
    bots.to_s.split(/[\n,]/).collect(&:strip)
  end
  
  def bots_user_agent_regexp
    Regexp.new("(#{bots_to_filter.collect {|a| Regexp.escape(a)}.join('|')})", Regexp::IGNORECASE)
  end
  
  def bot_request?
    request.user_agent.present? && bots_to_filter.present? && request.user_agent.match(bots_user_agent_regexp)
  end
end

ApplicationController.send :include, RedmineBotsFilter
ApplicationController.send :before_filter, :bots_filter
