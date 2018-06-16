module Origen
  module Commands

  # A single command.
  # Some of the command utilities depend on it being in a group.
  class Command
    class Scope
      attr_reader :scope

      def initialize(scope)
        @scope = scope
      end

      def shared?
        scope == :shared
      end

      def test?
        scope == :test
      end

      def global?
        scope == :global
      end

      def application?
        scope == :application
      end
      alias_method :app?, :application?
    end
    # require optparse here to the commands themselves don't have too.
    #require 'optparse'

    attr_reader :name
    attr_reader :scope
    #attr_reader :description
    #attr_reader :option_handler
    #attr_reader :body
    #attr_reader :extends
    attr_reader :aliases
    attr_reader :namespace
    attr_reader :expansions
    attr_reader :expansion_load_order
    #attr_reader :namespace_aliases

    def initialize(name, scope, namespace, options={}, &block)
      @name = name
      @scope = Origen::Commands::Command::Scope.new(scope)
      @namespace = namespace
      @expansions = {}
      @aliases = []
      @option_parser = OptionParser.new do |opts|
        # Default option parser
        opts.on('-h', '--help', 'Prints this help message') do
          help!
        end
      end
      yield self

      # Run the collector on this to get an options/block hybrid.
      #opts = Origen::Utiltiy.collector(hash: options, merge_method: :keep_hash, &block).to_h
    end

    def nspace
      namespace
    end

    # Since namespaces are CommandGroups, group also makes sense.
    def group
      namespace
    end

    def aliases=(a)
      if a.is_a?(Array)
        @aliases = a.map { |i| i.to_s }
      else
        @aliases = [a.to_s]
      end
    end

    def responds_to_name?(n)
      name.to_s == n.to_s || aliases.include?(n.to_s)
    end

    ### MOVE THESE TO COLLECTOR ONCE COLLECTOR IS FINISHED - 4/21/2018 ###
    ### Actually... turns out we can't use the collector. :( So sad ###
    ### lolol.. actually should be able to ###

    def help(h=nil)
      if h
        @help = h
      else
        @help
      end
    end

    def body(process = nil, &block)
      if block_given?
        @body = block
      elsif process
        @body = process
      else
        @body
      end
    end

    def description(desc=nil)
      if desc
        @description = @desc
      else
        @description || "No Description Available!".red
      end
    end

    def option_parser(&block)
      if block_given?
        block.call(@option_parser)
      else
        @option_parser
      end
    end
    alias_method :opt_parser, :option_parser

    ### END COLLECTOR MOVES ###

    def load_expansions!
      expansion_load_order.each do |exp|
        load_expansion!(_expansions[exp])
      end
    end
    
    def load_expansion!(exp)
      puts "Loading expansion: #{exp.name}"
    end

    def launch(options={}, &block)
      # Load the expansions at launch time (allows for dynamic control)
      load_expansions!
      
      # Handle the input arguments
      puts options
      @argv =  options[:argv].nil? ? [] : options[:argv].clone
      option_parser.parse!(@argv)
      
      # ?
      body.call(options, block)
    end

    def provider
      fail
    end

    def to_console(options={})
      puts " #{name}    #{description}"
    end
    
    def argv
      @argv
    end
    alias_method :input_args, :argv
    alias_method :input_arguments, :argv
    
    def input_options
      @input_options ||= {}
    end
    alias_method :input_opts, :input_options
    alias_method :argo, :input_options
    
    # Expands the command. This is a shortcut/coding style command to get the command first, then expand it
    # (as opposed to expanding the handler, or adding a handler then linking the command)
    # This has the same affect as handler.expand(cmd, ...)
    def expand(name, options={}, &block)
      # Since the command requires a namespace, which requires, a handler, we can try to get the current context
      # from this command's handler.
      # If we can't, then the expansion will require that the namespace be passed in either on the option or on the block
      
      #namespace = self.namespace.provider.command_handler.current_namespace
      #provider = self.namespace.provider.command_handler.current_provider
      #expansion = Origen::Commands::Expansion.new(name, self, namespace, provider, options, &block)
      #expansions[expansion.name] = expansion
      #expansion
      
      namespace = self.namespace.provider.command_handler.current_namespace
      namespace.expand(name, self, options, &block)
    end
    
    def _add_expansion(exp)
      expansions[exp.name] = exp
    end
  end

    # Expands and overwrites certain behavior in a command.
    class Expansion
      attr_reader :pre_body
      attr_reader :post_body
      attr_reader :option_parser
      attr_reader :description
      attr_reader :body

      attr_reader :expanded_command
      attr_reader :namespace
      attr_reader :provider
      attr_reader :name

      def initialize(name, command_to_expand, namespace, provider, options={}, &block)
        @name = name
        @expanded_command = command_to_expand
        @namespace = namespace
        @provider = provider
        
        command_to_expand._add_expansion(self)
        
        if block_given?
          yield(self)
        end
        
        #@name = options[:name] || "expansion_#{self.object_id}_for_#{command_to_expand}"
        
        # Register the extension on the command
        #@extended_command = command_to_extended
        #@extended_command.register_extension
      end
      
      #def option_parser(options={}, &block)
      #  if block_given?
      #    yield(@expanded_command.option_parser)
      #  else
      #    @expanded_command.option_parser
      #  end
      #end
      
      def expand(options={}, &block)
        fail 'not done yet!'
      end
      
      def responds_to_name?(n)
        name.to_s == n.to_s #|| aliases.include?(n.to_s)
      end
    end

  end
end
