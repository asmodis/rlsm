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

task :test_monoid => :build_ext do
  ruby "test/test_monoid.rb"
end

task :create_gem do
  sh "gem build rlsm.gemspec"
  sh "mv *.gem gem/"
end
