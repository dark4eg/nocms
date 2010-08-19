# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{nocms}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Darren Rush"]
  s.date = %q{2010-08-18}
  s.description = %q{A Ruby client for the NOCMS.org web service API.  Provides server-side helpers for Rails/Sinatra/Rack applications. keywords: ruby, rails, sinatra, rack, CMS, content management systems, search, cloud, SAAS, JSON, web service}
  s.email = %q{nocms@powcloud.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/nocms.rb",
     "nocms.gemspec",
     "test/helper.rb",
     "test/test_nocms.rb"
  ]
  s.homepage = %q{http://github.com/powcloud/nocms}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A Ruby client for the NOCMS.org web service API.  Provides server-side helpers for Rails/Sinatra/Rack applications.}
  s.test_files = [
    "test/helper.rb",
     "test/test_nocms.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_runtime_dependency(%q<active_support>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_dependency(%q<active_support>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    s.add_dependency(%q<active_support>, [">= 0"])
  end
end

