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
           (controller_name == 'issues' && (action_name == 'calendar' || !params[:query_id].blank?)) ||
           (controller_name == 'gantts') ||
           (controller_name == 'wiki' && (action_name == 'history' || !params[:version].blank?))
           
        render :text => 'Bots are not allowed to view this page.', :layout => false, :status => 403
        return false
      end
    end
    true
  end
  
  BOTS_USER_AGENT = ['googlebot', 
                     'yahoo! slurp',
                     'msnbot',
                     'baiduspider',
                     'yandex',
                     'spider',
                     'robot']
                     
  BOTS_USER_AGENT_RE = Regexp.new("(#{BOTS_USER_AGENT.collect {|a| Regexp.escape(a)}.join('|')})", Regexp::IGNORECASE)
  
  def bot_request?
    request.user_agent.present? && request.user_agent.match(BOTS_USER_AGENT_RE)
  end
end

ApplicationController.send :include, RedmineBotsFilter
ApplicationController.send :before_filter, :bots_filter
