Redmine::Plugin.register :redmine_wikifileattach do
  name 'Redmine Wikifileattach plugin'
  author 'Eugene Seliverstov'
  description 'Allows to include dynamically updated wikipage from a file'
  version '0.0.1'
#  url 'http://github.com/theirix/redmine_wikifileattach'

  settings :default => {'wikifileattach_directory' => ""},
    :partial => 'settings/wikifileattach_settings'
end

require 'redmine_wikifileattach'