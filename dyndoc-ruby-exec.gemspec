require 'rubygems'
require 'rubygems/package_task'

PKG_NAME='dyndoc-ruby-exec'
PKG_VERSION='0.1.0'

PKG_FILES=FileList[
    'lib/dyndoc-converter.rb','lib/dyndoc-software.rb'
]

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "Converters and software for dyndoc"
    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.licenses = ['MIT', 'GPL-2']
    s.requirements << 'none'
    s.require_path = 'lib'
    s.files = PKG_FILES.to_a
    s.description = <<-EOF
  Converters and software for dyndoc.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end