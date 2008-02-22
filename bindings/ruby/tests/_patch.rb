
#
# Code11 Patch
#

class Item
  attr_reader :name, :evr, :arch
  def initialize name, evr, arch
    @name = name
    @evr = evr
    @arch = arch
  end
  def to_s
    "#{name} #{evr} #{arch}"
  end
end 

class Patch
  attr_reader :name, :evr
  attr_reader :timestamp, :category
  attr_reader :summary, :description
  attr_reader :contains
  
  def initialize name, evr, category, timestamp
    @name = name
    @evr = evr
    @category = category
    @timestamp = timestamp
    @contains = []
  end
  
  def summary= summary
    @summary = summary
  end
  def description= description
    @description = description
  end
  
  def add name,evr,arch
    @contains << Item.new( name, evr, arch )
  end
  
  def to_s
    s = "Name: #{@name}-#{@evr}\n" +
        "  Category: #{@category}\n" +
        "  Timestamp: #{@timestamp}\n" +
        "  Summary: #{@summary}\n" +
	"  Contains[#{@contains.size}]:\n"
    @contains.each { |i| s += "    #{i}\n" }
    s
  end
end
