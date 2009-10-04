# -*- ruby -*-

require File.join(File.dirname(__FILE__), 'lib', 'rlsm')

task :build_ext do
  Dir.chdir File.join(File.dirname(__FILE__), 'ext') do
    Dir.foreach('.') do |extension|
      Dir.chdir extension do
        if File.exists? 'extconf.rb'
          ruby 'extconf.rb'
          sh "make"
        end
      end
    end
  end
end

task :test => :build_ext do
  Dir.chdir File.join(File.dirname(__FILE__), 'test') do
    Dir.glob("test_*").each do |file|
      ruby file
    end
  end
end

task :create_manifest do
  Dir.chdir(File.dirname(__FILE__)) do
    File.open("Manifest", 'w') do |manifest|
      FileList['lib/**/*.rb', 'ext/**/*.c','ext/**/*.rb', 'test/**/*'].to_a.each do |file|
        manifest.puts file
      end

      manifest.puts "Rakefile"
      manifest.puts "README"
    end
  end
end

task :create_gemspec => :create_manifest do
  Dir.chdir(File.dirname(__FILE__)) do
    readme = File.open("README")
    manifest = File.open("Manifest")
    filelist = "[" + manifest.to_a.map { |line| "'#{line.chomp}'" }.join(", ") + "]"
    manifest.close

    readme_string = '<<DESCRIPTION' + "\n" + readme.to_a.join + "\nDESCRIPTION"
    readme.close

    File.open(".gemspec", 'w') do |gemspec|
      gemspec.puts <<GEMSPEC
# -*- ruby -*-

require "rake"

Gem::Specification.new do |s|
  s.author = "Gunther Diemant"
  s.email = "g.diemant@gmx.net"
  s.homepage = "http://github.com/asmodis/rlsm"
  s.rubyforge_project = 'rlsm'

  s.name = 'rlsm'
  s.version = '#{RLSM::VERSION}'
  s.add_development_dependency('minitest')
  s.add_development_dependency('thoughtbot-shoulda')
  s.summary = "Library for investigating regular languages and syntactic monoids."
  s.description = #{readme_string}

  s.files = #{filelist}
  s.test_files = FileList['test/test_*.rb']
  s.extensions = FileList['ext/**/extconf.rb']

  s.has_rdoc = true
  s.extra_rdoc_files = ['README']
  s.rdoc_options << '--main' << 'README'
end
GEMSPEC
    end
  end
end

task :create_gem => :create_gemspec do
  sh "gem build .gemspec"
  sh "mv *.gem gem/"
end
