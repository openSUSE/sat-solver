$:.unshift "../../../build/bindings/ruby"

#
# Generate 'code11 updateinfo' from (code10) patch solv
#

#
# Output XML tag
#  - indented by 2xindent spaces
#  - with attrs (hash) as attributes
#     if attrs include nil=>nil, close tag
#  - with text as text
#
# returns:
#   string for closing tag (if text non-nil and non-empty)
#   nil else
#

def xmlout tag, indent, attrs=nil
  lead = ""
  indent.times { lead << "  " }
  print "#{lead}<#{tag}"
  if attrs.is_a? Hash                  # output attributes key="value"
    doclose = false
    attrs.each { |k,v|
      if k.nil?
	doclose = true
      else
        print " #{k}=\"#{v}\""
      end
    } 
    if doclose
      puts "/>"
      return nil
    end
  elsif attrs.is_a? String
    if attrs.empty?                    # empty string? -> close tag immediately
      puts "/>"
    else
      attrs.gsub!( "<", "&lt;" )
      attrs.gsub!( ">", "&gt;" )
      puts ">#{attrs}</#{tag}>"        # text</tag>
    end
    return nil
  end
  puts ">"
  return "#{lead}</#{tag}>"          # return closing tag
end


require 'satsolver'
require '_patch'
require '_solv2patches'

pool = Satsolver::Pool.new( "x86_64" )
repo = pool.create_repo( "patches" )

#
# convert solv file to array of Patch
#


Dir.foreach( "patches" ) { |solvname|
#  STDERR.puts "Reading #{solvname}"
  next if solvname[0,1] == "."
  repo.add_solv( "patches/#{solvname}" )
}

STDERR.puts "Converting now ..."
patches = solv2patches nil, repo

puts "<?xml version=\"1.0\"?>"
puts "<updates>"

indent = 1
patches.each { |p|
#  STDERR.puts "#{p.name}-#{p.evr}"
  endtag = xmlout "update", indent, "from" => "maint-coord@suse.de", "status"=>"stable", "type"=>p.category, "version"=>"11.0"
  indent += 1
  xmlout "id", indent, "#{p.name}-#{p.evr}"
  xmlout "title", indent, p.summary
  xmlout "release", indent, "openSUSE 11.0"
  xmlout "issued", indent, "date" => p.timestamp, nil => nil
  xmlout "references", indent, ""
  xmlout "description", indent, p.description
  listend = xmlout "pkglist", indent
  indent += 1
  collend = xmlout "collection", indent
  indent += 1
  p.contains.each { |item|
    vr = item.evr.split "-"
    pkgend = xmlout "package", indent, "name" => item.name, "version" => vr[0], "release" => vr[1], "arch" => item.arch
    xmlout "filename", indent+1, "#{item.name}-#{item.evr}.#{item.arch}.rpm"
    xmlout( "reboot_suggested", indent+1, "True" ) if p.reboot
    xmlout( "restart_suggested", indent+1, "True" ) if p.restart
    puts pkgend
  }
  indent -= 1
  puts collend
  indent -= 1
  puts listend
  indent -= 1
  puts endtag
}

puts "</updates>"
