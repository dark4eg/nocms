require 'active_support'
require 'net/http'
require 'uri'
require 'cgi'
 
@@nocms_pages = nil

# This is a default, that might be override by the app
@@nocms_lang_default = 'en'

def nocms_can_edit?()
  settings.environment != :production
end

def nocms_block(id, options = {})
  raise 'Must specify an element id as the first parameter. :tag and :content are optional params' if id.nil?

  tag = options[:tag] ||= 'div'
  site = options[:site] ||= settings.nocms_site ||= request.host_with_port
  path = options[:path] ||= request.path_info
  lang = options[:lang] ||= request.env['HTTP_ACCEPT_LANGUAGE'].nil? ? nil : request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first ||= 'en'
  
  if @@nocms_pages.nil? || @@nocms_pages_updated_at < Time.now - 3*60 
    @@nocms_pages_updated_at = Time.now
    rq = "http://api.nocms.org/nocms/1.0/export?site=#{site}"
    json = Net::HTTP.get(URI.parse(rq))  
    results = ActiveSupport::JSON.decode(json)
    @@nocms_pages = Hash.new
    results.each do |block|
      p = block['block']
      @@nocms_pages["#{p['path']}:#{p['xpath']}"] = p['content']
    end
    puts "Loaded #{results.length} blocks"
  end
  
  content = @@nocms_pages["/#{lang}#{path}:#{id}"] ||=  @@nocms_pages["/#{@@nocms_lang_default}:#{path}:#{id}"] ||= options[:default] ||= 'Lorem ipsum'
      
  # "%#{tag}\##{id}.edit #{content}" 
  "<#{tag} id='#{id}' class='nocms_edit'>#{content}</#{tag}>"
end