module Dyndoc

  SOFTWARE={}

  def self.mingw32_software?
    RUBY_PLATFORM=~/mingw32/
  end

  def self.scoop_install?
    self.mingw32_software? and !(`where scoop`.strip.empty?)
  end

  def self.software_init(force=false)

    unless SOFTWARE[:R]
      if self.mingw32_software?
        cmd=Dir[File.join(ENV["HomeDrive"],"Program Files","R","**","R.exe")]
        SOFTWARE[:R]=cmd[0] unless cmd.empty?
      else
        cmd=`type "R"`
        SOFTWARE[:R]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
    end

    unless SOFTWARE[:Rscript]
      if self.mingw32_software?
        cmd=Dir[File.join(ENV["HomeDrive"],"Program Files","R","**","Rscript.exe")]
        SOFTWARE[:Rscript]=cmd[0] unless cmd.empty?
      else
        cmd=`type "Rscript"`
        SOFTWARE[:R]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
    end

    unless SOFTWARE[:ruby]
      cmd=`type "ruby"`
      SOFTWARE[:ruby]=cmd.strip.split(" ")[2] unless cmd.empty?
    end

    unless SOFTWARE[:pdflatex]
      cmd=`type "pdflatex"`
      if RUBY_PLATFORM =~ /msys/
        SOFTWARE[:pdflatex]="pdflatex"
      else
        SOFTWARE[:pdflatex]=cmd.empty? ? "pdflatex" : cmd.strip.split(" ")[2]
      end
    end

    unless SOFTWARE[:pandoc]
      if File.exist? File.join(ENV["HOME"],".cabal","bin","pandoc")
        SOFTWARE[:pandoc]=File.join(ENV["HOME"],".cabal","bin","pandoc")
      else
        begin
          cmd = `which pandoc`.strip
        rescue
          cmd = "pandoc"
        end
        SOFTWARE[:pandoc]=cmd unless cmd.empty?
        #cmd=`type "pandoc"`
        #SOFTWARE[:pandoc]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
    end

    unless SOFTWARE[:ttm]
      cmd=`type "ttm"`
      SOFTWARE[:ttm]=cmd.strip.split(" ")[2] unless cmd.empty?
    end

    unless SOFTWARE[:bash]
      if self.scoop_install?
        bash_path=File.expand_path('../../bin/bash.exe',`scoop which git`)
        if File.exist? bash_path
          bash_path
        else # Needs to be in the PATH
          "bash"
        end
      else
        "/bin/bash"
      end
    end

  end

  def self.software
    SOFTWARE
  end

  def self.software?(software)
    software - SOFTWARE.keys
  end

  def self.pdflatex
    # this has to be initialized each time you need pdflatex since TEXINPUTS could change!
    if ENV['TEXINPUTS']
      "env TEXINPUTS=#{ENV['TEXINPUTS']}" + (self.mingw32_software? ? "; " : " ") + SOFTWARE[:pdflatex]
    else
      SOFTWARE[:pdflatex]
    end
  end

  def self.bash(bash_path=nil)
    bash_path # Needs to be in the PATH
      return bash_path
    else
      SOFTWARE[:bash]
    end
  end

  def self.R
    SOFTWARE[:R]
  end

  self.software_init

end
