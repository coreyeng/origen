module Origen
  module Optionable
    require 'origen/optionable/option'
    require 'origen/optionable/option_group'
  
    # Errors thrown by the Option & OptionHandler classes
    class UnacceptedValueError < Origen::OrigenError; end
    class AcceptedCheckerFailed < Origen::OrigenError; end
    class UnacceptedClassError < Origen::OrigenError; end
    class UnsetValueError < Origen::OrigenError; end
    class Error < Origen::OrigenError; end
    
    # Errors thrown by the OptionHandler
    class UnknownOptionError < Origen::OrigenError; end
    class NameInUseError < Origen::OrigenError; end
    
    class Optionable
      
      # Do not add accessors. Force the use of options[] to get options.
      COMPONENTABLE_ADDS_ACCESSORS = false
      
      # Force a better name for Optionable. We'll use option and options.
      include Origen::Componentable
    
      def initialize
        Origen::Componentable.init_includer_class(self)
        
        @parent_group = OptionGroup.new name: "Top", option_handler: self
      end
      
      # Override Componentable's :add  method.
      # We're doing a few things differently here:
      #  1. We're not allowing :instances to be used. Have multiple instances of the same option doesn't really
      #     make sense. So, just bailing on that.
      #  2. We're not allowing any other classes to be used. We're forcing everything to use the
      #     Origen::Optionable::Option class. This class will take care of checking that requirements are met,
      #     storing it, etc.
      def add(name, options={}, &block)
        # merge the given options with any that are overriden with the block.
        if block_given?
          collector = Origen::Utility::Collector.new
          yield collector
          options.merge!(collector.store)
        end
        
        if options.key?(:instances)
          raise Error, 'Optionable does not allow multiple instances of an option!'
        end
        
        if options.key?(:class_name)
          raise Error, 'Optionable does not allow a :class_name to be specified. Optionable forces all added objects to be of class Origen::Optionable::Option'
        end
        
        if @_componentable_container.key?(name)
          raise NameInUseError, "Optionable has already registered an option :#{name}"
        end
        
        @_componentable_container[name] = Option.new(name, options)
      end
      
    	def groups
    	  @parent_group
    	end
    
      def _options
        @_componentable_container
      end
      
      def fetch(opt)
        puts "Fetching: #{opt}".red
        puts "#{_options.keys}".to_s.yellow
        _options[opt]
      end
      
      def requirements_met?
        # Go through each option, in the order that they were registered, and see if the requirements are met
        missing_opts = missing_required_options
        missing_opts.empty?
      end
      
      def missing_required_options
        missing_opts = []
        _options.each do |name, option|
          unless option.requirement_met?
            missing_opts << name
          end
        end
        missing_opts
      end
      
      def merge_ordering
        _options.keys
      end
      
      def merge(options_to_merge, merging_options={})
        fail_on_extra_options = (merging_options[:fail_on_extra_options] != false)
        fail_on_requirements_check = (merging_options[:requirements_check] != false)
        
        
        missing = missing_required_options
        if fail_on_requirements_check && !missing.empty?
          missing = missing.map { |name| ":#{name}" }.join(', ')
          raise Error, "Not all requirements met! Missing options #{missing}"
        end
        
        # Will be deleting stuff out of this, but don't want to affect the user's argument.
        # Also convert to with indifferent access so we can use key? without worrying about String/Symbol conversions.
        opts = ActiveSupport::HashWithIndifferentAccess.new(options_to_merge)
        merge_ordering.each do |opt_name|
          _options[opt_name].set(opts.delete(opt_name)) if opts.key?(opt_name)
        end
        
        if !opts.empty? && fail_on_extra_options
          leftovers = opts.keys.map { |name| ":#{name}" }.join(', ')
          raise UnknownOptionError, "Option(s) #{leftovers} were given but are not registered options."
        end
      end
      
    	def to_html(options={})
    	  #panel_name = (options[:panel_name] || ("Options for #{parent}" if parent) || 'Optionable Options') + ' (Click To Expand)'
    	  panel_name = options.delete(:title) || "#{Origen.app.namespace} Options"
    	  collapse_id = options[:collapse_id] || Random.rand(1..2**16)
    	  propogate_collapse_id = options[:propogate_collapse_id] || false
    	  
    	  html = []
    	  html << '<div class="panel-group">'
    	  html << '  <div class="panel panel-default">'
    	  html << '    <div class="panel-heading">'
    	  html << '      <h4 class="panel-title">'
    	  html << '        <a data-toggle="collapse" href="#optionable_' + "#{collapse_id}" + '">' + panel_name + '</a>'
    	  html << '      </h4>'
    	  html << '    </div>'

        #collapse = groups.start_collapsed
     	  if options.delete(:top_starts_collapsed).is_a?(FalseClass) || options[:start_collapsed].is_a?(FalseClass)
    	    html << '    <div id="optionable_' + "#{collapse_id}" + '" class="panel-collapse collapse in">'
    	  else
    	    html << '    <div id="optionable_' + "#{collapse_id}" + '" class="panel-collapse collapse">'
    	  end
    	  html << '      <ul class="list-group">'
    	  
    	  # Keep track of which options we've seen and which ones we haven't.
    	  # We'll put all ungrouped options on the top level.
    	  # Also, we'll print some warnings regarding ungrouped options, unless all are ungrouped. Then we'll ignore.
    	  grouped_options = _options.each_with_object({}) {|(name, val), hash| hash[name] = false }
    	  puts grouped_options
    	  
    	  collapse_id = nil unless propogate_collapse_id
    	  if groups._groups.empty?
      	  _options.each do |name, opt|
      	    # Create a new list item
      	    html << '<li class="list-group-item">'
      	    html << opt.to_html(collapse_id: collapse_id)
      	    html << '</li>'
      	  end
    	  else
      	  html << '<li class="list-group-item">'
      	  html << groups._to_html(collapse_id: collapse_id)
      	  html << '</li>'
      	end
    	  
    	  html << '      </ul>'
    	  html << '    </div>'
    	  
    	  html << '  </div>'
    	  html << '</div>'
    	  
    	  html.join("\n")
    	end

      def generate_docs(options={})
        to_html(options)
      end

    end
    
    def set_optionable(name, value)
      if optionable.has?(name)
        optionable[name].set(value)
      else
        raise UnknownOptionError, "Option :#{name} is not a registered option!"
      end
    end
    
    def merge_optionable(options_to_merge, merging_options={})
      optionable.merge(options_to_merge, merging_options)
    end
    
    def optionable_merge_ordering
      optionable.merge_ordering
    end
    
    # When Origen's model initializer is included, all Componentable objects will be automatically booted.
    #def self.included(othermod)
      #puts "OPTIONABLE!!!"
      #othermod.define_singleton_method(:origen_model_init) do |klass, options={}|
      #  klass.instance_variable_set(:@_option_handler, Origen::OptionHandler.new)
      #end
    #end
    
    # Module Instance Methods
=begin    
    def _option_handler
      # Put a safeguard in case the user didn't include Origen::Model. If the @_option_handler isn't available yet,
      # make one.
      instance_variable_get(:@_option_handler)
    end
    
    def add_option(*args)
      #_option_handler.add(
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
    
    def self.origen_model_init(klass, options={})
      klass.instance_variable_set(:@_option_handler, Origen::Optionable::OptionHandler.new)
    end
=end    
  end
end
