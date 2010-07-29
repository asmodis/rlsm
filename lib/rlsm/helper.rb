
module RLSM
  # The exception class which is raised by the code under the RLSM module.
  # So somthing like
  #    begin
  #      ...
  #    rescue RLSM::Error => e
  #      ... #Error from RLSM code
  #    rescue
  #      ... #Some external error
  #    end
  # works.
  class Error < StandardError; end
  
  def self.require_extension(extension)
    require File.join(File.dirname(__FILE__), '..', '..', 'ext', extension, extension + '_cext')
  end
end
