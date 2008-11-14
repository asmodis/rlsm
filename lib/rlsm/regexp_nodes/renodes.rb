
#Monkey Patching the RLSM constant.
module RLSM
end

#Loading the node types
require File.join(File.dirname(__FILE__), "primexp")
require File.join(File.dirname(__FILE__), "star")
require File.join(File.dirname(__FILE__), "union")
require File.join(File.dirname(__FILE__), "concat")

module RLSM::RENodes
  
  #Simplifiying the counting of parenthesis
  PCount = Hash.new(0)
  PCount['('] = 1
  PCount[')'] = -1

  #Creates a new tree for the given description +desc+ and parent node +parent+
  def self.new(desc, parent=nil)
    #Convert a string description to an array
    desc = desc.scan(/./m) if desc.class == String

    ##Some a priori simplifications
    #Removing surrounding parentheses
    desc = desc[(1..-2)] while sp?(desc)

    #Squeezing repeated *'s and &'s and *&'s and &*'s
    #This is required only  once, so if the parent isn't nil, there should be no need to do this again.
    unless parent
      desc = desc.inject([]) do |res,char|
        [char,res.last].all? { |c| ['*', '&'].include? c } ? res : res + [char]
      end
    end
        
    ##Determine the correct node type and return it
    if prim?(desc)
      return PrimExp.new(parent, desc)
    elsif star?(desc)
      return Star.new(parent, desc)
    elsif union?(desc)
      return Union.new(parent,desc)
    else
      return Concat.new(parent,desc)
    end
  end

  def self.sp?(desc)
    if desc[0,1].include? '(' and desc[-1,1].include? ')'
      state = 0
      l = 0
      #count = Hash.new(0)
      #count['('] = 1
      #count[')'] = -1
        
      desc.each_char do |c|
        state += PCount[c]
        l += 1
        break if state == 0
      end
          
      return true if desc.length == l
    end
      
    false
  end

  def self.prim?(desc)
    not ['(', ')', '|', '*'].any? { |c| desc.include? c }
  end

  def self.star?(desc)
    if desc[-1,1].include? '*'
      return true if sp?(desc[(0..-2)]) #something like (....)*
      return true if desc.length == 2  #something like a*
    end
      
    false
  end

  def self.union?(desc)
    state = 0
    #count = Hash.new(0)
    #count['('] = 1
    #count[')'] = -1

    desc.each_char do |c|
      state += PCount[c]

      return true if c == '|' and state == 0
    end

    false
  end
end
