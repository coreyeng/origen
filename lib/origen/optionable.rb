module Origen
  module Optionable
  
    # Errors thrown by the Option & OptionHandler classes
    class UnacceptedValueError < Origen::OrigenError; end
    class AcceptedCheckerFailed < Origen::OrigenError; end
    class UnacceptedClassError < Origen::OrigenError; end
    class UnsetValueError < Origen::OrigenError; end
    class Error < Origen::OrigenError; end
    
    # Errors thrown by the OptionHandler
    class UnknownOptionError < Origen::OrigenError; end
    class NameInUseError < Origen::OrigenError; end
    
    # Class to handle a single option instance
    class Option
      #attr_reader :parent
      attr_reader :name
      attr_reader :description
      attr_reader :current_value
      #attr_reader :has_been_set
      attr_reader :default
      attr_reader :doc_group
      attr_reader :accepted_classes
      attr_reader :accepted_values
      attr_reader :accepted_checker
      attr_reader :default_is_nil
      #attr_reader :required
      
      ACCEPTED_OPTIONS = [:description, :default, :doc_group, :accepted_classes,
                          :accepted_values, :accepted_checker
      ]
      
      def initialize(name, options={})
        validate_self(options)
        @name = name
        @has_been_set = false
        
        @default = options[:default]
        set(options[:default]) if options[:default]
      end
      
      def set(value)
        validate_input(value)
        @current_value = value
        @has_been_set = true
      end
      
      def has_been_set?
        @has_been_set
      end
      
      def value
        unless has_been_set?
          raise UnsetValueError, "Tried to retrieve the value for option '#{name}' but it has not been set yet nor has a default value!"
        end
        current_value
      end
      
      def validate_input(value)
        unless accepted_classes.nil?
          unless accepted_classes.include?(value.class)
            raise UnacceptedClassError, "Class '#{value.class}' is not accepted for option '#{name}'. Accepted classes are: #{accepted_classes}"
          end
        end
        
        unless accepted_checker.nil?
          unless @accepted_checker.call(value)
            raise AcceptedCheckerFailed, "Value '#{value}' failed to pass the given checker!"
          end
        end
        
        unless accepted_values.nil?
          unless accepted_values.include?(value)
            raise UnacceptedValueError, "Value '#{value}' is not accepted for option '#{name}'. Accepted values are: #{accepted_values}"
          end
        end
      end
      
      def validate_self(options)
        @accepted_values = options[:accepted_values]
        @accepted_classes = options[:accepted_classes]
        @accepted_checker = options[:accepted_checker]
        
        @description = options[:description]
        @doc_group = options[:doc_group]
        
        @required = options[:required] || false
      end
      
      def required?
        @required
      end
    end
    
    class OptionHandler
      attr_reader :options
      attr_reader :option_groups
      attr_reader :parent
      
    	def initialize(options={})
    	  @options = Hash.new
    	  @option_groups = {groups: {}, no_description: true, options: {}}
    	end
    	
    	def _option_groups
    	  @option_groups
    	end
    	
    	def _options
    	  @options
    	end
    	
    	# Allow for a few different ways of adding options.
    	# A. Passing in a single name/option pair:
    	# B. Passing in pairs of name/options:
    	# C. Passing in already created options:
    	# D. Giving the options a block.
    	# A/B are mutually exclusive, but can be mixed with C (detects Option class vs. Symbol class)
    	# (?) D is run after A/B. So, if A/B and D are the same options, A/B will work, but D will complain that
    	#  the options already exists.
    	def add(*args)
    	  i = 0
    	  while i < args.size
    	    if args[i].is_a?(Origen::Optionable::Option)
    	      opt = args[i]
    	      if _options.key?(opt.name)
    	        raise NameInUseError, "Option :#{opt.name} has already been registered!"
    	      else
    	        _options[opt.name] = opt
    	      end
    	      i += 1
    	    else
    	      #_options[arg[i], arg[i+1]]
    	      if _options.key?(args[i])
    	        raise NameInUseError, "Option :#{args[i]} has already been registered!"
    	      end
    	      opt = Origen::Optionable::Option.new(args[i], args[i+1])
    	      _options[args[i]] = opt
    	      i += 2
    	    end
    	  end
    	end
    	
    	def set(*args)
    	  i = 0
    	  while i < args.size
    	    name = args[i].is_a?(Option) ? args[i].name : args[i]
    	    val = args[i+1]
    	    if !_options.key?(name)
    	      raise UnknownOptionError, "Option :#{name} is not a registered option!"
    	    end
    	    _options[name].set(val)
    	    i += 2
    	  end
    	end
    	
    	# Given an Hash, will go through and set each option that it finds in opts
    	# Keys that opts has that are not in options are ignored.
    	def merge(opts)
    	  opts.each { |name, val| set(name, val) if @options.key?(name) }
    	end
    	
    	# Given an Hash, will go through and set each option that it finds in opts
    	# Keys that opts has that are not in options will result in errors
    	def merge!(opts)
    	  # take the difference of opts.keys and @options.keys.
    	  # if the result is empty, all keys in opts were found.
    	  # if not, complain about the extra keys.
    	  if (opts.keys - @options.keys).empty?
    	    merge(opts)
    	  else
    	    raise UnknownOptionError, "The following options were given but are not registered options: #{opts.keys - @options.keys}"
    	  end
    	end
    	
    	# Retrieves the currrent value of the specific option
    	def [](key)
    	  value(key)
    	end
    	
    	def value(*args)
    	  i = 0
    	  ret = []
    	  while i < args.size
    	    name = args[i]
    	    if _options.key?(name)
    	      ret << _options[name].value
    	    else
    	      raise UnknownOptionError, "Option :#{name} is not a registered option!"
    	    end
    	    i += 1
    	  end
    	  ret.size == 1 ? ret.first : ret
    	end
    	
    	def []=(key, val)
    	  if _options.key?(key) && val.class != Hash
    	    # Use as a set method
    	    set(key, val)
    	  else
    	    # Use as an add method
      	  if val.is_a?(Option)
      	    unless key == val.name
      	      raise Origen::Optionable::Error, "Given name :#{key} doesn't match option name :#{val.name}"
      	    end
      	    add(val)
      	  else
        	  add(key, val)
        	end
      	end
    	end
    	
    	# Retrieves the option instance, not just the value
    	def retrieve(*args)
    	  i = 0
    	  ret = []
    	  while i < args.size
    	    name = args[i]
    	    if _options.key?(name)
    	      ret << _options[name]
    	    else
    	      raise UnknownOptionError, "Option :#{name} is not a registered option!"
    	    end
    	    i += 1
    	  end
    	  ret.size == 1 ? ret.first : ret
    	end
    	alias_method :fetch, :retrieve
    	
    	def remove(*args)
    	  i = 0
    	  ret = []
    	  while i < args.size
    	    name = args[i]
    	    if _options.key?(name)
    	      ret << _options.delete(name)
    	    else
    	      raise UnknownOptionError, "Option :#{name} is not a registered option!"
    	    end
    	    i += 1
    	  end
    	  ret.size == 1 ? ret.first : ret
    	end
    	
    	def list
    	  _options.keys
    	end
    	
    	def values_to_html(option={})
    	end
    	
    	def add_option_group(new_group, options={})
    	  #def add_group(group, context, options)
    	  #  context[group] = options
    	  #end
    	    
    	  context = @option_groups
    	  if new_group.is_a? Array
    	    new_group.each_with_index do |group, index|
    	      unless context.key?(:groups)
    	        context[:groups] = {}
    	      end
    	      
    	      if index == (new_group.size - 1)
    	        # We've reached the last group. so pass the options along with this one.
    	        (context[:groups])[group] = {groups: {}}.merge(options)
    	      elsif context[:groups].key?(group)
    	        # The group was found. Shift the context to that group and get the next one.
    	        context = (context[:groups])[group]
    	      else
    	        # The group wasn't found so add a new one, then advance the context
    	        (context[:groups])[group] = {groups: {}}
    	        context = (context[:groups])[group]
    	      end
    	    end
    	  else
    	    # for this, context is @option_groups which has a :groups key by default.
      	  (context[:groups])[new_group] = {groups: {}}.merge(options)
      	end
    	end
    	
    	def set_option_group(options, group)
    	  def add_option_to_group(context, g)
    	    if options.is_a? Array
    	      if @options.context?
    	      end
    	    else
    	    end
    	  end
    	  
    	  context = @option_groups
    	  if group.is_a? Array
    	  else
    	    add_options_to_groups(context)
    	  end
    	end
    	
      def has_option_group?(group)
      end
      
      # Sets option's group to group.
      # Unlike set_option_group, if the group doesn't exists, it will create it instead.
      def _force_option_group(option, group)
      end
    	
    	def to_html(options={})
    	  panel_name = (options[:panel_name] || ("Options for #{parent}" if parent) || 'Optionable Options') + ' (Click To Expand)'
    	  html = []
    	  html << '<div class="panel-group">'
    	  html << '  <div class="panel panel-default">'
    	  html << '    <div class="panel-heading">'
    	  html << '      <h4 class="panel-title">'
    	  #html << '        <a data-toggle="collapse" href="#collapse1">Collapsible list group</a>'
    	  html << '        <a data-toggle="collapse" href="#optionable_' + "#{self.object_id}" + '">' + panel_name + '</a>'
    	  html << '      </h4>'
    	  html << '    </div>'

    	  html << '    <div id="optionable_' + "#{self.object_id}" + '" class="panel-collapse collapse">'
    	  html << '      <ul class="list-group">'
    	  
    	  _options.each do |name, opt|
    	    # Create a new list item
    	    html << '<li class="list-group-item">'
    	    
    	    # Create a new panel header for the option name and panel body for the content
          html << "<div class='panel panel-default'>"
          html << "<div class='panel-heading'><h4>#{name}</h4></div>"
          html << "<div class='panel-body'>"
          
          # Print the description if it has one. If not, complain about it.
          if opt.description == "" || opt.description.nil?
            html << "<p>No Description Available</p>"
            Origen.log.warning "No description available for parameter #{param.name}"
          else
            if opt.description.is_a?(Array)
              opt.description.each do |line|
                html << "<p>#{line}</p>"
              end
            else
              html << "<p>#{opt.description}</p>"
            end
          end
          
          # Print the default value and its class
          if opt.default == ""
            html << "<p>Default: (Empty String) (String)</p>"
          else
            html << "<p>Default: #{opt.default} (#{opt.default.class})</p>"
          end
          
          # Print the accepted classes/values and whether or not an accepted process is present
          if opt.accepted_classes
            html << "Accepted Classes: <p>#{opt.accepted_classes.join(', ')}</p>"
          end
          
          if opt.accepted_values
            html << "Accepted Values: <p>#{opt.accepted_values.join(', ')}</p>"
          end
          
          if opt.accepted_checker
            html << "Accpted Checker: <p>Has as accepted checker block</p>"
          end
          
          # Close the panel div, panel body, and list item
          html << '</div>' # End Panel Body
          html << '</div>' # End Panel Div
    	    html << '</li>'
    	  end
    	  
    	  html << '      </ul>'
    	  html << '    </div>'
    	  
    	  html << '  </div>'
    	  html << '</div>'
    	  
    	  html.join("\n")
    	end
    	
    	def generate_html(options={})
    	end
    end
  
    def add_option(name, options)
      
    end
    alias_method :add_options, :add_option
    
    def set_option(name, options)
    end
    
    def remove_option
    end
    alias_method :remove_options, :remove_option
    
    def list_options
    end
    
    def retrieve_option
    end
    alias_method :retrieve_options, :retrieve_option
    alias_method :get_option, :retrieve_option
    alias_method :get_options, :retrieve_option
    
    def generate_options_html
    end
    
    def self.included(othermod)
      othermod.class_eval do |klass|
        define_method :_optionable_handler do
          @_optionable_handler ||= Origen::Optionable::OptionHandler.new
        end
      end
    end
    
  end
end
