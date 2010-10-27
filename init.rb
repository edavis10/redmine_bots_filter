require 'redmine'
require 'bots_filter'

Redmine::Plugin.register :redmine_bots_filter do
  name 'Bots filter'
  author 'Jean-Philippe Lang'
  description 'Prevent bots from crawling alternate formats links and various part of the application.'
  version '1.02'
end
