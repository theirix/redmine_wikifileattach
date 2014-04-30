require 'redmine/menu_manager'
require 'redmine/themes'
require 'application_helper'

module RedmineWikifileattach

  class Helper
    class << self
      def log_it s
        Rails.logger.debug(s) if Rails.logger && Rails.logger.debug?
      end
      
      def settings_directory
        Setting.plugin_redmine_wikifileattach['wikifileattach_directory']
      end
      
      def ensure_wikipage filename, wikiname, project, current_page
        raise 'No wikipage directory specified' if settings_directory.empty?
        
        # check correct path
        path = File.join(settings_directory, filename)
        checked_path = File.expand_path(File.join(settings_directory, filename))
        raise "Suspicious filename #{checked_path}" if checked_path != path
        raise "File with wikipage is not found at path '#{path}'" if !File.file?(path)

        Helper::log_it "Includewikifile looking to path #{path} and wikiname #{wikiname}"

        # find existing page
        page = Wiki.find_page(wikiname.to_s, :project => project)
      
        if page
          page.destroy unless page.content

          mtime = File.stat(path).mtime
          if page.updated_on < mtime
            # reload page
            Helper::log_it "Page is outdated (#{mtime} vs #{page.updated_on}), adding new version"
            page.content.text = IO.read(path)
            page.save_with_content page.content
          end
        else
          # add page
          Helper::log_it "Adding a new page #{wikiname}"

          new_page = WikiPage.new(wiki_id: project.wiki.id, title: wikiname, parent_id: current_page.id)
          new_page.build_content(author_id: User.anonymous.id, text: IO.read(path))
          new_page.save
        end
        
      end

      def parse_macro_args args
         raise 'Wrong arguments of macro ' if args.size < 1 || args.size > 2
         filename = args[0].to_s
         wikiname = args.size > 1 ? args[1].to_s : ''
         wikiname = File.basename(filename, File.extname(filename)) if wikiname.empty?
         [filename, wikiname]
      end
    end
  end
    
  Redmine::WikiFormatting::Macros.register do
    desc "Include a wikipage from a file:\n\n" +
    " @!{{includewikifile(filename, [wikiname])}}@\n"
    " @!{{includewikicodefile(filename, [wikiname])}}@\n"
    " @!{{referwikifile(filename, [wikiname])}}@\n"
    
    macro :includewikifile do |obj, args|
      filename, wikiname = Helper::parse_macro_args args
      Helper::ensure_wikipage filename, wikiname, @project, @page
    
      textilizable("{{include(#{wikiname})}}")
    end
    
    macro :includewikicodefile do |obj, args|
      filename, wikiname = Helper::parse_macro_args args
      Helper::ensure_wikipage filename, wikiname, @project, @page

      # extracted from 'include' macro
      page = Wiki.find_page(wikiname, :project => @project)
      raise 'Page not found' if page.nil? || !User.current.allowed_to?(:view_wiki_pages, page.wiki.project)
      textilizable("<pre\n>" + page.content.text + "</pre>", :attachments => page.attachments, :headings => false)
    end

    macro :referwikifile do |obj, args|
      filename, wikiname = Helper::parse_macro_args args
      Helper::ensure_wikipage filename, wikiname, @project, @page
    
      ""
    end
        
  end
end
