require 'helper'

class NocmsTests < Test::Unit::TestCase
  NoCMS::Base.site = 'powcloud.com:not-so-secret'

  should "run diagnostics" do
    puts NoCMS::Base.diagnostic
  end
  
  should "load cache" do
    NoCMS::Base.ensure_cache()
  end
end
