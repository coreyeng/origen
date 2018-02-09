module Origen
  module Optionable
  
    class OptionGroup
      attr_reader :_name
      attr_reader :_parent
      attr_reader :_options
      attr_reader :_groups
      attr_reader :_description
      attr_reader :_handler
      attr_reader :_display_name
      
      def initialize(*args)
        if args.last.is_a? Hash
          opts = args.delete_at(-1)
        else
          opts = {}
        end
        
        @_name = opts.delete(:name)
        if @_name.nil?
          raise Error, 'A name must be provided to instantiate an option group!'
        end
        
        # Handler differs from parent in this case.
        # The parent represents the group to which this group is a subgroup of.
        # A parent of nil implies it is a top level group.
        # Handler is the optionhandler object that contains all the options.
        # This is used to check for option existance, and to generate the option
        @_handler = opts.delete(:option_handler)
        if @_handler.nil?
          raise Error, 'An Origen::Optionable::Optionable object must be given to instantiate an option group!'
        end
        unless @_handler.is_a?(Origen::Optionable::Optionable)
          raise Error, "An OptionGroup's handler must be of class Origen::Optionable::Optionable!. Received class: #{@_handler.class}"
        end
        
        @_groups = {}
        @_options = []
        
        _config(opts)
        
        @_display_name = name.to_s.split('_').map(&:capitalize).join(' ') if @_display_name.nil?
        
        _add(args) if args.size >= 1
      end
      
      def name
        _name
      end
      
      def _add(*args)
        args.each do |name|
          @_options << name
        end
      end
      
      def _config(opts)
        available_opts = [:parent, :description, :start_expanded, :display_name]
        opts.each do |opt, val|
          if available_opts.include?(opt)
            if opt == :start_expanded && (val != true && val != false)
              raise Error, "Config variable :start_expanded for OptionGroup #{_name} must be either true or false! Received: #{val}"
            end
            self.instance_variable_set("@_#{opt}".to_sym, val)
          else
            raise Error, "Unknown config option :#{opt} was given. Available config options are: #{available_opts}"
          end
        end
      end
      
      def _generate_order(options={})
        if @_order.is_a?(Array)
          # Replace any group/option instances with the name
          @_order.map do |i|
            if i.is_a?(OptionGroup) || i.is_a?(Option)
              i.name
            else
              i
            end
          end
        elsif @_order == :groups_first
          _groups.keys + _options
        elsif @_order == :options_first
          _options + _groups.keys
        else
          fail "Unknown @_order value: #{@_order}"
        end
      end
      
      def _order
        @_order ||= :groups_first
      end
      
      def _order=(new_order)
        if new_order.is_a?(Array)
          new_order.each do |opt_or_group|
            unless _has_option?(opt_or_group) || _has_group?(opt_or_group)
              if opt_or_group.is_a?(Option)
                raise UnknownOptionError, "Problem setting order in OptionGroup '#{_name}': Unknown option instance '#{opt_or_group.name}'"
              elsif opt_or_group.is_a?(OptionGroup)
                raise UnknownOptionError, "Problem setting order in OptionGroup '#{_name}': Unknown group instance '#{opt_or_group.name}'"
              else
                raise UnknownOptionError, "Problem setting order in OptionGroup '#{_name}': Unknown option or group '#{opt_or_group}'"
              end
            end
          end
          @_order = new_order.clone
          return @_order
        elsif new_order.is_a?(Symbol)
          if new_order == :groups_first
            @_order = :groups_first
            return @_order
          elsif new_order == :options_first
            @_order = :options_first
            return @_order
          end
        end
        raise Error, "Unknown order '#{new_order}'! Available values are :groups_first, :options_first or an Array containing a custom order"
      end
      
      def _has_option?(opt)
        if opt.is_a?(Option)
          opt = opt.name
        end
        _options.include?(opt)
      end
      
      def _has_group?(opt)
        if opt.is_a?(OptionGroup)
          opt = opt.name
        end
        _groups.key?(opt)
      end
      
      def _shift_option_up(*args)
        args.each do |opt|
        end
      end
      alias_method :_shift_options_up, :_shift_option_up
      
      def _shift_option_down(*args)
        args.each do |opt|
        end
      end
      alias_method :_shift_options_down, :_shift_option_down
      
      # Method missing will define a new group
      def method_missing(method, *args, &block)
        _define_group(method, *args)
      end
      
      def _define_group(name, *args)
        puts "Defining args: #{args}"
        if args.last.is_a? Hash
          args[-1] = { name: name, option_handler: _handler, parent: self }.merge(args.last)
        else
          args << { name: name, option_handler: _handler, parent: self }
        end
        @_groups[name] = OptionGroup.new(*args)
        
        define_singleton_method name do |*args|
          if args.size == 0
            @_groups[name]
          else
            if args.last.is_a?(Hash)
              puts "ARGS: #{name} #{args}"
              @_groups[name]._config(args.pop)
              @_groups[name]._add(*args)
            else
              @_groups[name]._add(*args)
            end
          end
        end
        
        @_groups[name]
      end
      
      def _start_collapsed?
        !_start_expanded?
      end
      
      def _start_expanded?
        @_start_expanded ||= false
      end
      
      # Generates the option list for this group.
      # This will be a self-contained group.
      def _to_html(options={})
        
        html = []
        collapse_id = options[:collapse_id] || Random.rand(1..2**16)
        
    	  html << '<div class="panel-group">'
    	  html << '  <div class="panel panel-default">'
    	  html << '    <div class="panel-heading">'
    	  html << '      <h4 class="panel-title">'
    	  #html << '        <a data-toggle="collapse" href="#collapse1">Collapsible list group</a>'
    	  html << '        <a data-toggle="collapse" href="#optionable_' + "#{collapse_id}" + '">' + _display_name + '</a>'
    	  html << '      </h4>'
    	  html << '    </div>'
        
    	  html << '    <div id="optionable_' + "#{collapse_id}" + '" class="panel-collapse collapse">'
    	  html << '      <ul class="list-group">'
    	  
    	  # Add any options at this group level
    	  _options.each do |opt_name|
    	    puts opt_name.to_s.green
    	    html << '<li class="list-group-item">'
    	    html << _handler.fetch(opt_name).to_html
    	    html << '</li>'
    	  end
    	  
    	  # Add any subgroups of this group.
    	  _groups.each do |group_name, group|
    	    html << '<li class="list-group-item">'
    	    html << group._to_html
    	    html << '</li>'
    	  end
    	  
    	  html << '      </ul>'
    	  html << '    </div>'
    	  
    	  html << '  </div>'
    	  html << '</div>'
    	  
    	  html.join("\n")
      end
    end
  
  end
end
