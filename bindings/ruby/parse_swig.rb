# Classes and modules built in to the interpreter. We need
# these to define superclasses of user objects

require "rdoc/code_objects"
require "rdoc/parsers/parserfactory"
require "rdoc/options"
require "rdoc/rdoc"

module RDoc

  class Context
    attr_accessor :body
  end
  
  class Swig_Parser

    attr_accessor :progress

    extend ParserFactory
    parse_files_matching(/\.i$/)

    @@known_bodies = {}
    @@files_seen = Array.new
    @@module_name = nil
    
    # prepare to parse a SWIG file
    def initialize(top_level, file_name, body, options, stats)
      @known_classes = KNOWN_CLASSES.dup
      @body = handle_tab_width(handle_ifdefs_in(body))
      @options = options
      @stats   = stats
      @top_level = top_level
      @classes = Hash.new
      @file_dir = File.dirname(file_name)
      @progress = $stderr unless options.quiet
      @file_name = file_name
    end

    # Extract the classes/modules and methods from a C file
    # and return the corresponding top-level object
    def scan
      unless @@files_seen.include? @file_name
	@@files_seen << @file_name
	remove_commented_out_lines
	if module_name = do_module
	  @@module_name = module_name
	else
	  do_classes
	  @classes.keys.each do |c|
	    do_constants c
	    do_methods c
	    do_includes
	    do_aliases c
	    end
	  end
      else
	puts "Seen #{@file_name} before" unless @options.quiet
      end
      @top_level
    end

    #######
    private
    #######

    def progress(char)
      unless @options.quiet
        @progress.print(char)
        @progress.flush
      end
    end

    def warn(msg)
      $stderr.puts
      $stderr.puts msg
      $stderr.flush
    end

    def remove_private_comments(comment)
       comment.gsub!(/\/?\*--(.*?)\/?\*\+\+/m, '')
       comment.sub!(/\/?\*--.*/m, '')
    end

    ##
    # removes lines that are commented out that might otherwise get picked up
    # when scanning for classes and methods

    def remove_commented_out_lines
      @body.gsub!(%r{//.*rb_define_}, '//')
    end

    ##
    # handle class or module
    #
    # return enclosure
    #   
    def handle_class_module(class_mod, class_name, options = {})
#      puts "handle_class_module(#{class_mod}, #{class_name})"
      progress(class_mod[0, 1])
      parent = options[:parent]
      parent_name = @known_classes[parent] || parent

      if @@module_name
        enclosure = @top_level.find_module_named(@@module_name)
      else
        enclosure = @top_level
      end

      if class_mod == "class" 
        cm = enclosure.add_class(NormalClass, class_name, parent_name)
        @stats.num_classes += 1
      else
        cm = enclosure.add_module(NormalModule, class_name)
        @stats.num_modules += 1
      end
      cm.record_location(enclosure.toplevel)
      cm.body = options[:content]

      find_class_comment(class_name, cm)
      @classes[class_name] = cm
      @known_classes[class_name] = cm.full_name
    end

    ##
    # Look for class or module documentation above %extend +class_name+
    # in a Document-class +class_name+ (or module) comment or above an
    # rb_define_class (or module).  If a comment is supplied above a matching
    # Init_ and a rb_define_class the Init_ comment is used.
    #
    #   /*
    #    * This is a comment for Foo
    #    */
    #   %extend Foo {
    #     ...
    #   }
    #

    def find_class_comment(class_name, class_meth)
#      puts "find_class_comment(#{class_name}, #{class_meth})"
      comment = nil
      if @body =~ %r{((?>/\*.*?\*/\s+))
                     %extend\s+#{class_name}\s*\{}xmi
        comment = $1
      elsif @body =~ %r{Document-(class|module):\s#{class_name}\s*?\n((?>.*?\*/))}m
        comment = $2
      else
        if @body =~ /rb_define_(class|module)/m then
          class_name = class_name.split("::").last
          comments = []
          @body.split(/(\/\*.*?\*\/)\s*?\n/m).each_with_index do |chunk, index|
            comments[index] = chunk
            if chunk =~ /rb_define_(class|module).*?"(#{class_name})"/m then
              comment = comments[index-1]
              break
            end
          end
        end
      end
      class_meth.comment = mangle_comment(comment) if comment
    end
    
    ############################################################

    #
    # Find module
    # return module_name (or nil)
    #
    def do_module
      module_name = nil
      @body.scan(/^%module\s*(\w+)/mx) do 
        |name|
	module_name = name[0].capitalize
	handle_class_module("module", module_name)
      end
      module_name
    end

    #
    # Find and handle classes within +module_name+
    #
    # return Array of classes
    #
    def do_classes

      # look for class renames like
      #   %rename(Solvable) _Solvable;
      #   typedef struct _Solvable {} XSolvable; /* expose XSolvable as 'Solvable' */

      extends = Hash.new
      @body.scan(/^%rename\s*\(([^\"\)]+)\)\s+(\w+);/) do |class_name, struct_name|
#	puts "rename #{class_name} -> #{struct_name}"
	@body.scan(/typedef\s+struct\s+#{struct_name}\s*\{[^}]*\}\s*(\w+);/) do |extend_name|
#	  puts "extend #{extend_name}"
	  @body.scan(/^%extend\s+#{extend_name}\s*\{(.*)\}/mx) do |content|
	    extends[extend_name.to_s] = true
	    swig_class = handle_class_module("class", class_name.to_s.capitalize, :parent => "rb_cObject", :content => content.to_s)
	  end
	end
      end
      @body.scan(/^%extend\s*(\w+)\s*\{(.*)\}/mx) do |class_name,content|
	unless extends[class_name]
	  handle_class_module("class", class_name.capitalize, :parent => "rb_cObject", :content => content)
	  extends[class_name] = true
	end
      end
    end

    ###########################################################

    #
    # Find
    #  %constant +type+ +name+ = +value+
    #
    def do_constants class_name
      c = find_class class_name
      c.body.scan(%r{%constant\s+(\w+)\s+(\w+)\s*=\s*(\w+)\s*;}xm) do
        |type, const_name, definition|
        # swig puts all constants under module
	handle_constants(type, @@module_name, const_name, definition)
      end
    end
    
    ############################################################
    
    #
    # Find and handle all methods for +module_name+::+class_name+
    #
    # Look for C-Function headers within the class content
    #  const? +type+ +name+ ( +args+ ) {
    # and honor
    #  %rename "+new_name+" +old_name+ ;
    #
    def do_methods class_name
      renames = Hash.new
      c = find_class class_name
      c.body.scan(%r{%rename\s*\(\s*"([^"]+)"\s*\)\s*(\w+)}m) do #"
        |meth_name,orig_name|
	meth_name = meth_name[0] if meth_name.is_a? Array
	orig_name = orig_name[0] if orig_name.is_a? Array
        renames[orig_name] = meth_name
      end
      # Find function definitions of the format
      #   <type> [*]? <name> ( <args> ) {
      #
#      puts "#{module_name}::#{class_name} methods ?"
      c = find_class class_name
      c.body.scan(%r{^\s+((const\s+)?\w+)(\W+)(\w+)\s*\(([^\)]*)\)\s*\{}m) do
        |type,const,pointer,meth_name,args|
	next unless meth_name
	type = "string" if type =~ /char/ && pointer =~ /\*/
#	puts "-> #{const}:#{type}:#{pointer}:#{meth_name} ( #{args} )\n#{$&}\n\n"
	meth_name = meth_name[0] if meth_name.is_a? Array
	meth_name = renames[meth_name] || meth_name
        handle_method(type, class_name, meth_name, nil, (args.split(",")||[]).size)
      end

   end

    ############################################################
    
    #
    # Find and handle method aliases
    #
    #  %alias +old_name+ "+new_name+" ;
    #
    def do_aliases class_name
      c = find_class class_name
      c.body.scan(%r{%alias\s+(\w+)\s+"([^"]+)"\s*;}m) do #"
        |old_name, new_name|
        @stats.num_methods += 1
        raise "Unknown class '#{class_name}'" unless @known_classes[class_name]
        class_obj  = find_class(class_name)

        class_obj.add_alias(Alias.new("", old_name, new_name, ""))
      end
   end

    ##
    # Adds constant comments.  By providing some_value: at the start ofthe
    # comment you can override the C value of the comment to give a friendly
    # definition.
    #
    #   /* 300: The perfect score in bowling */
    #   rb_define_const(cFoo, "PERFECT", INT2FIX(300);
    #
    # Will override +INT2FIX(300)+ with the value +300+ in the output RDoc.
    # Values may include quotes and escaped colons (\:).

    def handle_constants(type, class_name, const_name, definition)
      class_obj = find_class(class_name)
      unless class_obj
        warn("Enclosing class/module for '#{const_name}' not known")
        return
      end
      
      comment = find_const_comment(type, const_name)

      # In the case of rb_define_const, the definition and comment are in
      # "/* definition: comment */" form.  The literal ':' and '\' characters
      # can be escaped with a backslash.
      if type.downcase == 'const' then
         elements = mangle_comment(comment).split(':')
         if elements.nil? or elements.empty? then
            con = Constant.new(const_name, definition, mangle_comment(comment))
         else
            new_definition = elements[0..-2].join(':')
            if new_definition.empty? then # Default to literal C definition
               new_definition = definition
            else
               new_definition.gsub!("\:", ":")
               new_definition.gsub!("\\", '\\')
            end
            new_definition.sub!(/\A(\s+)/, '')
            new_comment = $1.nil? ? elements.last : "#{$1}#{elements.last.lstrip}"
            con = Constant.new(const_name, new_definition,
                               mangle_comment(new_comment))
         end
      else
         con = Constant.new(const_name, definition, mangle_comment(comment))
      end

      class_obj.add_constant(con)
    end

    ##
    # Finds a comment matching +type+ and +const_name+ either above the
    # comment or in the matching Document- section.

    def find_const_comment(type, const_name)
      if @body =~ %r{((?>^\s*/\*.*?\*/\s+))
	             %constant\s+(\w+)\s+#{const_name}\s*=\s*(\w+)\s*;}xmi
        $1
      elsif @body =~ %r{Document-(?:const|global|variable):\s#{const_name}\s*?\n((?>.*?\*/))}m
        $1
      else
        ''
      end
    end

    ###########################################################

    def handle_attr(var_name, attr_name, reader, writer)
      rw = ''
      if reader 
        #@stats.num_methods += 1
        rw << 'R'
      end
      if writer
        #@stats.num_methods += 1
        rw << 'W'
      end

      class_name = @known_classes[var_name]

      return unless class_name
      
      class_obj  = find_class(class_name)

      if class_obj
        comment = find_attr_comment(attr_name)
        unless comment.empty?
          comment = mangle_comment(comment)
        end
        att = Attr.new('', attr_name, rw, comment)
        class_obj.add_attribute(att)
      end

    end

    ###########################################################

    def find_attr_comment(attr_name)
      if @body =~ %r{((?>/\*.*?\*/\s+))
                     rb_define_attr\((?:\s*(\w+),)?\s*"#{attr_name}"\s*,.*?\)\s*;}xmi
        $1
      elsif @body =~ %r{Document-attr:\s#{attr_name}\s*?\n((?>.*?\*/))}m
        $1
      else
        ''
      end
    end

    ###########################################################

    def handle_method(type, class_name, meth_name, 
                      meth_body, param_count)
      progress(".")
      @stats.num_methods += 1

      class_obj  = find_class(class_name)
      if class_obj
        if meth_name == "initialize"
          meth_name = "new"
          type = "singleton_method"
        end
        meth_obj = AnyMethod.new("", meth_name)
        meth_obj.singleton =
	  %w{singleton_method module_function}.include?(type) 
        
        p_count = (Integer(param_count) rescue -1)
        
        if p_count < 0
          meth_obj.params = "(...)"
        elsif p_count == 0
          meth_obj.params = "()"
        else
          meth_obj.params = "(" +
                            (1..p_count).map{|i| "p#{i}"}.join(", ") + 
                                                ")"
        end

	body = find_class(class_name).body

        if find_body(meth_name, meth_obj, body) and meth_obj.document_self
          class_obj.add_method(meth_obj)
        end
      end
    end
    
    ############################################################

    # Find the C code corresponding to a Ruby method
    def find_body(meth_name, meth_obj, body, quiet = false)
#      puts "Find body for #{meth_name}"
      case body
      when %r{((?>/\*.*?\*/\s*))(?:const\s+)?(\w+)[\s\*]+#{meth_name}
              \s*(\(.*?\)).*?^}xm
        comment, params = $1, $2
        body_text = $&
#puts "Comment for #{meth_name} is #{comment}"
        remove_private_comments(comment) if comment

        # see if we can find the whole body
        
        re = Regexp.escape(body_text) + '[^(]*^\{.*?^\}'
        if Regexp.new(re, Regexp::MULTILINE).match(body)
          body_text = $&
        end

        # The comment block may have been overridden with a
        # 'Document-method' block. This happens in the interpreter
        # when multiple methods are vectored through to the same
        # C method but those methods are logically distinct (for
        # example Kernel.hash and Kernel.object_id share the same
        # implementation

        override_comment = find_override_comment(meth_obj.name)
        comment = override_comment if override_comment

        find_modifiers(comment, meth_obj) if comment
        
#        meth_obj.params = params
        meth_obj.start_collecting_tokens
        meth_obj.add_token(RubyToken::Token.new(1,1).set_text(body_text))
        meth_obj.comment = mangle_comment(comment)
      when %r{((?>/\*.*?\*/\s*))^\s*\#\s*define\s+#{meth_name}\s+(\w+)}m
        comment = $1
        find_body($2, meth_obj, body, true)
        find_modifiers(comment, meth_obj)
        meth_obj.comment = mangle_comment(comment) + meth_obj.comment
      when %r{^\s*\#\s*define\s+#{meth_name}\s+(\w+)}m
        unless find_body($1, meth_obj, body, true)
          warn "No definition for #{meth_name}" unless quiet
          return false
        end
      else

        # No body, but might still have an override comment
        comment = find_override_comment(meth_obj.name)

        if comment
          find_modifiers(comment, meth_obj)
          meth_obj.comment = mangle_comment(comment)
        else
#          warn "Dummy definition for #{meth_name}" unless quiet
#	  find_modifiers("unknown", meth_obj)
#          meth_obj.comment = mangle_comment("unknown") + meth_obj.comment
        end
      end
      true
    end


    ##
    # If the comment block contains a section that looks like:
    #
    #    call-seq:
    #        Array.new
    #        Array.new(10)
    #
    # use it for the parameters.

    def find_modifiers(comment, meth_obj)
      if comment.sub!(/:nodoc:\s*^\s*\*?\s*$/m, '') or
         comment.sub!(/\A\/\*\s*:nodoc:\s*\*\/\Z/, '')
        meth_obj.document_self = false
      end
      if comment.sub!(/call-seq:(.*?)^\s*\*?\s*$/m, '') or
         comment.sub!(/\A\/\*\s*call-seq:(.*?)\*\/\Z/, '')
        seq = $1
        seq.gsub!(/^\s*\*\s*/, '')
        meth_obj.call_seq = seq
      end
    end

    ############################################################

    def find_override_comment(meth_name)
      name = Regexp.escape(meth_name)
      if @body =~ %r{Document-method:\s#{name}\s*?\n((?>.*?\*/))}m
        $1
      end
    end

    ##
    # Look for includes of the form:
    #
    #    %mixin class "module";

    def do_includes
      @body.scan(/%mixin\s+(\w+)\s+"([^"]+)"s*;/) do |c,m| #"
        if cls = @classes[c]
          m = @known_classes[m] || m
          cls.add_include(Include.new(m, ""))
        end
      end
    end

    ##
    # Remove the /*'s and leading asterisks from C comments
    
    def mangle_comment(comment)
      comment.sub!(%r{/\*+}) { " " * $&.length }
      comment.sub!(%r{\*+/}) { " " * $&.length }
      comment.gsub!(/^[ \t]*\*/m) { " " * $&.length }
      comment
    end

    def find_class(name)
      @classes[name] || @top_level.find_module_named(name) || raise("No such class #{name}")
    end

    def handle_tab_width(body)
      if /\t/ =~ body
        tab_width = Options.instance.tab_width
        body.split(/\n/).map do |line|
          1 while line.gsub!(/\t+/) { ' ' * (tab_width*$&.length - $`.length % tab_width)}  && $~ #`
          line
        end .join("\n")
      else
        body
      end
    end

    ##
    # Removes #ifdefs that would otherwise confuse us
    
    def handle_ifdefs_in(body)
      body.gsub(/^#ifdef HAVE_PROTOTYPES.*?#else.*?\n(.*?)#endif.*?\n/m) { $1 }
    end
    
  end

end

