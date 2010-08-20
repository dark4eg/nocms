require 'active_support'
require 'net/http'
require 'uri'
require 'cgi'
 

# This is a default, that might be override by the app

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
      
      #@@nocms_lang_default = 'en'
      @@nocms_cache = NoCMS::Cache.new

      def environment
        return RAILS_ENV if rails?
        return (!!defined? settings && !settings.environment.nil?) ? settings.environment : 'development-nocms-test'
      end      

      def rails?
        !!defined? Rails
      end
    
      def diagnostic
        buffer = ''
        buffer += "NoCMS Diagnostics\n"
        buffer += "  Rails: #{rails?}\n"
        if rails?
          buffer += "    Cache Store: #{ActionController::Base.cache_store}\n"
          buffer += "    Cache (Object): #{Rails.cache}\n"
        end

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
      
      def load_cache
        start_time = Time.now
        raise '[NOCMS] Must specify a site' if NoCMS::Base.site.nil?

        cache.write("NOCMS:#{site}:updated_at", Marshal.dump(Time.now))
        
        # save this for a bit
        tmp = cache.read("NOCMS:#{site}:keys")
        old_keys = !tmp.nil? ? ActiveSupport::JSON.decode(tmp) : {}
        
        # load the new stuff
        rq = "http://api.nocms.org/nocms/1.0/export?site=#{site}"
        json = Net::HTTP.get(URI.parse(rq))  
        new_blocks = ActiveSupport::JSON.decode(json)
        #Rails.cache["NOCMS:#{site}:json"] = json
        cache.write("NOCMS:#{site}:keys", new_blocks.collect {|block| build_key(block['block']['path'], block['block']['xpath'])} )
         # add new keys and update existing
        new_blocks.each do |block|
          p = block['block']
          #@@nocms_pages["#{p['path']}:#{p['xpath']}"] = p['content']
          key = build_key(p['path'], p['xpath'])
          cache.write(key,  p['content'])
          old_keys.delete(key)
        end
        
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

#module ActionView
#  class Base

#    def nocms_block2(id, options = {})
#      "NOCMS WAS HERE!"
#    end
#  end
#end



def nocms_block(id, options = {})
  raise 'Must specify an element id as the first parameter. :tag and :content are optional params' if id.nil?
  
  #request = ActionController::Base.request ||= Sinatra::Base.request
  
  tag = options[:tag] ||= 'div'
  site = options[:site] ||= NoCMS::Base.site    # ||= request.host_with_port
  path = options[:path] ||= request.path ||= request.path_info
  lang = options[:lang] ||= request.env['HTTP_ACCEPT_LANGUAGE'].nil? ? nil : request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first ||= 'en'
  lang_default = NoCMS::Base.lang_default
  
  NoCMS::Base.ensure_cache()
  
  ## TODO: exception throw when these are consolidated????
  content = NoCMS::Base.cache.read(NoCMS::Base.build_key("/#{lang}#{path}", id))
  content = content ||= NoCMS::Base.cache.read(NoCMS::Base.build_key("/#{lang_default}#{path}", id)) if lang != lang_default
  content = content ||= options[:default] ||= 'Lorem ipsum'
      
  "<#{tag} id='#{id}' class='nocms_edit'>#{content}</#{tag}>"
end