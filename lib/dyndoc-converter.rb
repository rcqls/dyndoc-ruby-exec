# encoding: UTF-8

require "open3"
# begin
#   require 'redcloth'
# rescue LoadError
#   Dyndoc.warn "Warning: RedCloth not installed or supported!"
# end
#require 'pandoc-ruby'

module Dyndoc

  def Dyndoc.which_path(bin)
    begin
      cmd=`which #{bin}`.strip
      cmd=DyndocMsys2.global_path_msys2mingw(cmd) if RUBY_PLATFORM =~ /mingw/
    rescue
      cmd=bin
    end
    return cmd
  end

  module Converter

    SOFTWARE={}

    def Converter.mathlink(input)
      unless SOFTWARE[:mathlink]
        cmd=`type "math"`
        unless cmd.empty?
          require 'mathematica'
          SOFTWARE[:mathlink]=Mathematica::Mathematica.new.start  #cmd.strip.split(" ")[2] unless cmd.empty?
        end
      end
      SOFTWARE[:mathlink] ? SOFTWARE[:mathlink].eval_foreground(input) : ""
    end

    def Converter.pdflatex(input,opt='')
      output = ''
      unless SOFTWARE[:pdflatex]
        cmd=`type "pdflatex"`
        SOFTWARE[:pdflatex]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
      if SOFTWARE[:pdflatex]
        Open3.popen3("#{SOFTWARE[:pdflatex]} #{opt}") {|stdin,stdout,stderr|
          stdin.print input
          stdin.close
          output=stdout.read
        }
        return nil
      else
        $dyn_logger.write("ERROR pdflatex: software not installed!\n")
        return nil
      end
    end

    def Converter.pandoc_available?
      unless SOFTWARE[:pandoc]
        if File.exist? File.join(ENV["HOME"],".cabal","bin","pandoc")
          SOFTWARE[:pandoc]=File.join(ENV["HOME"],".cabal","bin","pandoc")
        else
          cmd = Dyndoc.which_path("pandoc")
          SOFTWARE[:pandoc]=cmd unless cmd.empty?
          #cmd=`type "pandoc"`
          #SOFTWARE[:pandoc]=cmd.strip.split(" ")[2] unless cmd.empty?
        end
      end
      SOFTWARE[:pandoc]
    end

    def Converter.pandoc(input,opt='')
      output = ''
      if Converter.pandoc_available?
        ##DEBUG: p [:pandoc_soft, SOFTWARE[:pandoc]+" #{opt}"]
        if input
          ##DEBUG: p [:pandoc_iput,input]
          ##DEBUG: p [:pandoc_options, opt]
          Open3::popen3(SOFTWARE[:pandoc]+" #{opt}") do |stdin, stdout, stderr|
            stdin.puts input
            stdin.close
            output = stdout.read.strip
          end
          ##DEBUG: p [:pandoc_output,output]
          output
        else
          ##DEBUG: p SOFTWARE[:pandoc]+" #{opt}"
          system(SOFTWARE[:pandoc]+" #{opt}")
        end
      else
        if $dyn_logger
          $dyn_logger.write("ERROR pandoc: software not installed!\n")
        else
          Dyndoc.warn "ERROR pandoc: software not installed!\n"
        end
        ""
      end
    end

# ttm converter
    def Converter.ttm(input,opt='-e2')
#puts "ttm:begin"
      output=nil
      unless SOFTWARE[:ttm]
        cmd=`type "ttm"`
        SOFTWARE[:ttm]=cmd.strip.split(" ")[2] unless cmd.empty?
      end
      if SOFTWARE[:ttm]
        Open3.popen3("#{SOFTWARE[:ttm]} #{opt}") {|stdin,stdout,stderr|
        	stdin.print input
        	stdin.close
        	output=stdout.read
  #puts "ttm:wait"
        }
  #puts "ttm:end"
        output.gsub("__VERBATIM__","verbatim").sub(/\A\n*/,"") #the last is because ttm adds 6 \n for nothing!
      else
         $dyn_logger.write("ERROR ttm: software not installed!\n")
        ""
      end
    end

    def Converter.asciidoctor(code)
      require 'asciidoctor'
      Asciidoctor.convert(code,:attributes => {"icons" => "font"})
    end

    def Converter.redcarpet_engine
      unless $$markdown
        require 'redcarpet'
        $$markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      end
      $$markdown
    end

    def Converter.redcarpet(code)
        Converter.redcarpet_engine ? $$markdown.render(code) : ""
    end

    def Converter.markdown(code,engine = :pandoc)
      if engine == :pandoc
        if Dyndoc::Converter.pandoc_available?
          Dyndoc::Converter.pandoc(code)
        else
          engine=:redcarpet
        end
      end
      Converter.redcarpet(code) if engine == :redcarpet
      ## default output if no engine found
      ""
    end

    def Converter.convert(input,format,outputFormat,to_protect=nil)
      ##
      format=format.to_s unless format.is_a? String
      ## Dyndoc.warn "convert input",[input,format]
      outputFormat=outputFormat.to_s unless outputFormat.is_a? String
      res=""
      input.split("__PROTECTED__FORMAT__").each_with_index do |code,i|
        ##Dyndoc.warn "code",[i,code,format,outputFormat]
        if i%2==0
          res << case format+outputFormat
          when "adoc>html"
            Dyndoc::Converter.asciidoctor(code)
          when "md>html"
            ##PandocRuby.new(code, :from => :markdown, :to => :html).convert
            Dyndoc::Converter.pandoc(code)
          when "md>tex"
            #puts "latex documentclass";p Dyndoc::Utils.dyndoc_globvar("_DOCUMENTCLASS_")
            if Dyndoc::Utils.dyndoc_globvar("_DOCUMENTCLASS_")=="beamer"
              Dyndoc::Converter.pandoc(code,"-t beamer")
            else
              Dyndoc::Converter.pandoc(code,"-t latex")
            end
          when "md>odt"
            ##PandocRuby.new(code, :from => :markdown, :to => :opendocument).convert
            Dyndoc::Converter.pandoc(code,"-t opendocument")
          when "txtl>html"
            # (rc=RedCloth.new(code))
            # rc.hard_breaks=false
            # rc.to_html
            Dyndoc::Converter.pandoc(code,"-f textile -t html")
          when "txtl>tex"
            # RedCloth.new(code).to_latex
            Dyndoc::Converter.pandoc(code,"-f textile -t latex")
          when "ttm>html"
            Dyndoc::Converter.ttm(code,"-e2 -r -y1 -L").gsub(/<mtable[^>]*>/,"<mtable>").gsub("\\ngtr","<mtext>&ngtr;</mtext>").gsub("\\nless","<mtext>&nless;</mtext>").gsub("&#232;","<mtext>&egrave;</mtext>")
          when "tex>odt"
            puts "tex => odt"
            tmp="<text:p><draw:frame draw:name=\""+`uuidgen`.strip+"\" draw:style-name=\"mml-inline\" text:anchor-type=\"as-char\" draw:z-index=\"0\" ><draw:object>"+Dyndoc::Converter.pandoc(code,"--mathml -f latex -t html").gsub(/<\/?p>/,"").gsub(/<(\/?)([^\<]*)>/) {|e| "<"+($1 ? $1 : "")+"math:"+$2+">"}+"</draw:object></draw:frame></text:p>"
            ##p tmp
            tmp
          when "tex>html"
            ##PandocRuby.new(code, :from => :markdown, :to => :html).convert
            Dyndoc::Converter.pandoc(code,"--mathjax -f latex -t html")
          when "ttm>tex", "html>html",'tex>tex'
            code
          else
            ## the rest returns nothing!
            Dyndoc.warn "Warning: unknown conversion!"
            ""
          end
        else
          res << code
        end
        #Dyndoc.warn "res",res
      end
      return (to_protect ? "__PROTECTED__FORMAT__"+res+"__PROTECTED__FORMAT__": res)
    end

  end
end
