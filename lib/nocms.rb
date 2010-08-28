require 'active_support'
require 'net/http'
require 'uri'
require 'cgi'
require 'set'

module NoCMS
  class Cache < Hash   
    def read(key)
      self[key]
    end
    
    def write(key, value)
      self[key] = value.to_s
    end
  end
  
  class Base
    class << self
      attr_accessor :site
      attr_accessor :lang_default
      
      NoCMS::Base.lang_default = 'en'
      
      @@nocms_cache = NoCMS::Cache.new

      def environment
        return RAILS_ENV if rails?
        return (!!defined? settings && !settings.environment.nil?) ? settings.environment : 'development-nocms-test'
      end      

      def rails?
        !!defined? Rails
      end
    
      def diagnostic
        buffer = "NoCMS Diagnostics\n"
        buffer += "  Rails: #{rails?}\n"
        buffer += "\tCache Store: #{ActionController::Base.cache_store}\n\tCache (Object): #{Rails.cache}\n" if rails?
        buffer += "  Cache: #{cache.class}\n"
        buffer += "  Environment: #{environment}\n"
        buffer += "  Site Key: #{site}\n"
        buffer += "  Default Language: #{lang_default}\n"
        buffer
      end
      
      def build_key(path, xpath)
        "NOCMS:#{path}:#{xpath}"
      end
      
      def cache()
        rails? ? Rails.cache : @@nocms_cache
      end
      
      def ensure_cache()
        tmp = cache.read("NOCMS:#{site}:updated_at")
        updated_at = Marshal.load(tmp) if !tmp.nil?
        load_cache if updated_at.nil? || updated_at < Time.now - 5*60  
      end
      
      def path_has_content?(request, path = nil, options = {})
        path ||= options.delete(:path) || request.path || request.path_info
        
        ensure_cache()
        
        lang = options.delete(:lang) || request.env['HTTP_ACCEPT_LANGUAGE'].nil? ? nil : request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first || 'en'
        lang_default = NoCMS::Base.lang_default

        tmp = cache.read("NOCMS:#{site}:paths")
        paths = !tmp.nil? ? Set.new(ActiveSupport::JSON.decode(tmp)) : Set.new

        return paths.include? "/#{lang}#{path}" if lang==lang_default
        paths.include?("/#{lang}#{path}") || paths.include?("/#{lang_default}#{path}")
      end
      
      def site_index()
        ensure_cache()
      
        tmp = cache.read("NOCMS:#{NoCMS::Base.site}:paths")
        paths = !tmp.nil? ? Set.new(ActiveSupport::JSON.decode(tmp)) : Set.new
        
        path_hash = {}
        paths.each { |p|
          matches = p.match /\/([^\/]+)(\/.*)/
          lang = matches[1]
          path = matches[2]
          path_hash[path] ||= Set.new
          path_hash[path] << lang
        }
        
        return path_hash
      end
            
      def load_cache
        start_time = Time.now
        raise '[NOCMS] Must specify a site' if NoCMS::Base.site.nil?

        cache.write("NOCMS:#{site}:updated_at", Marshal.dump(Time.now))
        
        # save this for a bit
        tmp = cache.read("NOCMS:#{site}:keys")
        old_keys = !tmp.nil? ? Set.new(ActiveSupport::JSON.decode(tmp)) : Set.new
        
        # load the new stuff
        rq = "http://api.nocms.org/nocms/1.0/export?site=#{site}"
        json = Net::HTTP.get(URI.parse(rq))  
        new_blocks = ActiveSupport::JSON.decode(json)
        
        keys = Set.new
        paths = Set.new 
        
         # add new keys and update existing
        new_blocks.each do |block|
          p = block['block']
          key = build_key(p['path'], p['xpath'])
          keys << key
          paths << p['path']
          cache.write(key,  p['content'])
          old_keys.delete(key)
        end

        cache.write("NOCMS:#{site}:paths", ActiveSupport::JSON.encode(paths))
        cache.write("NOCMS:#{site}:keys", ActiveSupport::JSON.encode(keys))
        
        # purge keys that have been deleted
        old_keys.each {|key| cache.delete(key)}
        
        updated_count = new_blocks.length
        deleted_count = old_keys.length
         
        puts "Loaded #{updated_count} blocks and deleted #{deleted_count} in #{Time.now-start_time}"  
      end

      def can_edit?()
        environment != :production
      end
    end
  end
end

def nocms_path_has_content?(path=nil, options={})
  NoCMS::Base.path_has_content?(request,path,options)
end

def nocms_block(id, options = {})

  tag  = options.delete(:tag)  || 'div'
  site = options.delete(:site) || NoCMS::Base.site    # ||= request.host_with_port
  path = options.delete(:path) || request.path || request.path_info
  lang = options.delete(:lang) || request.env['HTTP_ACCEPT_LANGUAGE'].nil? ? nil : request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first || 'en'
  lang_default = NoCMS::Base.lang_default

  raise 'Must specify an element id as the first parameter. :tag and :content are optional params' if id.nil?
  raise 'Path could not be determined, pass :path and ensure it is not nil' if path.nil?
  raise 'Site could not be determined.  Please set the NoCMS site variable per the documentation' if site.nil?  
  
  NoCMS::Base.ensure_cache()
  
  content = NoCMS::Base.cache.read(NoCMS::Base.build_key("/#{lang}#{path}", id)) 
  content ||= NoCMS::Base.cache.read(NoCMS::Base.build_key("/#{lang_default}#{path}", id)) if lang != lang_default 
  content ||= options.delete(:default) || 'Lorem ipsum'
  
  attr_class = ['nocms_edit']
  add_classes = options.delete(:class)
  attr_class += add_classes.split(' ') if !add_classes.nil?
 
  attributes = options.collect { |k,v| "#{k}='#{v}'" } if options.length > 0
      
  "<#{tag} id='#{id}' #{attributes} class='#{attr_class.join(" ").strip}'>#{content}</#{tag}>"
end

