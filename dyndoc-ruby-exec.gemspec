require 'rubygems'
require 'rubygems/package_task'

pkg_NAME='dyndoc-ruby-exec'
pkg_VERSION='0.1.0'

pkg_FILES=FileList[
    'lib/dyndoc-converter.rb','lib/dyndoc-software.rb'
]

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "Converters and software for dyndoc"
    s.name = pkg_NAME
    s.version = pkg_VERSION
    s.licenses = ['MIT', 'GPL-2']
    s.requirements << 'none'
    s.require_path = 'lib'
    s.files = pkg_FILES.to_a
    s.description = <<-EOF
  Converters and software for dyndoc.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end