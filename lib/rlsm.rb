module RLSM
  VERSION = "1.8.0"

  def self.lib_path_to(file_name)
    File.join(File.dirname(__FILE__), 'rlsm', file_name)
  end

  autoload :BinaryOperation, RLSM.lib_path_to("binary_operation.rb")
  autoload :Monoid, RLSM.lib_path_to("monoid.rb")
  autoload :DFA, RLSM.lib_path_to("dfa.rb")
  autoload :RegExp, RLSM.lib_path_to("regexp.rb")
end
  
