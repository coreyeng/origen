module Origen
  module Commands

  def self.to_namespace(path_str, options={})
  end

  # Command group applies to every command in it.
  class CommandGroup
    #attr_reader :commands
    attr_reader :provider
    attr_reader :aliases
    attr_reader :namespace
    attr_reader :parent
    attr_reader :_subgroups
    #attr_reader :_commands
    attr_reader :current_namespace
    attr_reader :_expansions

    def initialize(name, provider, parent, options={}, &block)
      @_commands = {}.with_indifferent_access
      @_expansions = {}.with_indifferent_access
      @current_namespace = self

      @provider = provider
      @parent = parent
      @namespace = name
      @aliases = []
      @_subgroups = {}.with_indifferent_access

      yield self if block_given?
    end

    def aliases=(a)
      if a.is_a?(Array)
        @aliases = a.map { |i| i.to_s }
      else
        @aliases = [a.to_s]
      end
    end

    def name
      namespace
    end

    def commands
      _commands.keys
    end

    def add_command(cmd, scope, options={}, &block)
      _commands[cmd] = Origen::Commands::Command.new(cmd.to_s, scope, self, options, &block)
    end
    alias_method :add, :add_command

      def add_shared_command(command, options={}, &block)
        self.add(command, :shared, options, &block)
      end
      alias_method :add_plugin_command, :add_shared_command
      alias_method :add_pl_command, :add_shared_command
      alias_method :add_pl_cmd, :add_shared_command
      alias_method :add_shared_cmd, :add_shared_command

      def add_application_command(command, options={}, &block)
        self.add(command, :application, options, &block)
      end
      alias_method :add_app_cmd, :add_application_command
      alias_method :add_application_cmd, :add_application_command

      def add_global_command(command, options={}, &block)
        self.add(command, :global, options, &block)
      end
      alias_method :add_global_cmd, :add_global_command

      def add_test_command(command, options={}, &block)
        self.add(command, :test, options, &block)
      end
      alias_method :add_test_cmd, :add_test_command


    def has_command?(cmd)
      !resolve_command(cmd).empty?
    end

    # The top namespace for any group is defined as its provider name.
    # This is the group accessed in order to get to 'self'.
    # For groups that represent a plugins's commands, this is the plugin's name.
    # i.e., plugin: or :plugin:
    # For groups that are a subgroup, the top namespace is the parent's name.
    # i.e., <plugin>:<parent_group>:
    def top_namespace
      provider.name
    end

    # Checks its namespace and aliases for the namespace.
    def has_namepace?(namespace)
      !resolve_namespaces.empty?
    end

    # The namespaces in this group.
    def namespaces
      namespace + aliases
    end

    # List only the nemespaces which are aliases.
    # Essentially, this is aliases - top_namespace
    def namespace_aliases
      aliases
    end

    def base_option_parser
    end

    def resolve_expansion(exp, options={})
      puts "exp: #{exp}"
      n = split(exp)
      puts "n split: #{n}"
      e = n.pop

      n = resolve_namespace(n)
      puts "n: #{n}"
      puts "e: #{e}"
      rtn = []
      n.each do |nspace|
        #rtn << nspace._commands[c] if nspace._commands.key?(c)
        #rtn += nspace._commands.select { |name, exp| exp.responds_to_name?(c) }.values
        rtn += nspace._expansions.select { |name, exp| exp.responds_to_name?(e) }.values
      end
      puts "RTN: #{rtn}"
      puts "aliases: #{aliases.join(',')}"
      rtn
    end

    # Returns the full path to this namespace.
    # E.g., a group derived directly from a plugin would be :<plugin>
    # A subgroup of the above would be :<plugin>:<name>
    # A subgroup of a subgroup of a subgroup would be :<plugin>:<group 1 name>:<group 2 name>:<name>
    def absolute_namespace
      # The bottom of the tree is when the parent is the provider. This is the top of the namespace tree
      if parent == provider
        ":#{top_namespace}"
      else
        "#{parent.absolute_namespace}:#{namespace}"
      end
    end

    def add_namespace(nspace, options={})
      s = Origen::Commands::CommandGroup.new(nspace, @provider, self, options)
      _subgroups[nspace] = s
      s
    end
    alias_method :add_nspace, :add_namespace
    alias_method :add_subgroup, :add_namespace

    def expand(exp_name, cmd, options, &block)
      expansion = Origen::Commands::Expansion.new(exp_name, cmd, self, @provider, options, &block)
      _expansions[expansion.name] = expansion
      expansion
    end

    # Returns the subgroups of the current group.
    def subgroups
      _subgroups.keys
    end
    #alias_methods :namespaces, :subgroup

    def namespace?(nspace)
      _subgroups.key?(nspace)
    end
    alias_method :subgroup?, :namespace?
    alias_method :has_subgroup?, :namespace?
    alias_method :has_namespace?, :namespace?

    # Returns the commands that satisfy the cmd.
    # NOTE: this returns an Array.
    # Empty array means no matching command was found.
    # Multiple commands imply an ambiguous command.
    def resolve_command(cmd)
      puts "cmd: #{cmd}"
      n = split(cmd)
      puts "n split: #{n}"
      c = n.pop

      n = resolve_namespace(n)
      puts "n: #{n}"
      puts "c: #{c}"
      rtn = []
      n.each do |nspace|
        #rtn << nspace._commands[c] if nspace._commands.key?(c)
        rtn += nspace._commands.select { |name, cmd| cmd.responds_to_name?(c) }.values
      end
      puts "RTN: #{rtn}"
      puts "aliases: #{aliases.join(',')}"
      rtn
    end

    # Split the cmd or nspace into its individual namespace and command components.
    # If the input is a cmd, then result.last will be the cmd
    def split(cmd_or_nspace)
      # Can't do just a straight string split here. We need to maintain a leading ':' symbol to denote an absolute namespace.
      tmp = cmd_or_nspace.dup
      rtn = cmd_or_nspace.start_with?(':') ? [tmp.slice!(0)] : []
      
      # Now we can.
      rtn += tmp.split(':')
      rtn
    end

    # Joins and array of nspace and a cmd into an absolute namespaced command.
    def join(cmd_or_nspace)
      ':' + cmd_or_nspace.join(':')
    end

    def top_namespace?
      provider == parent
    end

    def _commands(options={})
      if !options.key?(:scope)
        @_commands
      elsif options[:scope] == :shared
        @_commands.select { |name, comm| comm.scope.shared? }
      elsif options[:scope] == :test
        @_commands.select { |name, comm| comm.scope.test? }
      elsif options[:scope] == :global
        @_commands.select { |name, comm| comm.scope.global? }
      elsif options[:scope] == :application
        @_commands.select { |name, comm| comm.scope.app? }
      else
        fail "Unknonw scope: #{options[:scope]}"
      end
    end

    def shared_commands?
      !shared_commands.empty?
    end
    alias_method :has_shared_commands?, :shared_commands?

    def test_commands?
      !test_commands.empty?
    end
    alias_method :has_test_commands?, :test_commands?

    def global_commands?
      !global_commands.empty?
    end
    alias_method :hash_global_commands?, :global_commands?

    def application_commands?
      !application_commands.empty?
    end
    alias_method :has_application_commands?, :application_commands?
    alias_method :app_commands?, :application_commands?
    alias_method :has_app_commands?, :application_commands?

    def shared_commands(options={})
      _commands(scope: :shared)
    end

    def test_commands(options={})
      _commands(scope: :test)
    end

    def global_commands(options={})
      _commands(scope: :global)
    end

    def application_commands(options={})
      _commands(scope: :application)
    end
    alias_method :app_commands, :application_commands

    def path
    end

    # Returns the namespaces satisfying the given :nspace path within the current group.
    # This will be an Array of CommandGroups representing the namespaces.
    def resolve_namespace(nspace, options={})
      n = nspace.is_a?(Array) ? nspace : split(nspace)
      puts "resolve_namespace: nspace: #{n}"
      #puts n.class
      #current_nspace = n.shift
      puts "Current: #{self.name} (#{self.name.class})"

      # Attempts to mach the nspace given.
      # Breaks convention a bit since it doesn't return true or false, but returns the matching namespace object if it matches (as an array), or empty array
      def namespace_matches?(nspace, n_array)
        retn = []
        puts "namespace matches?"
        puts nspace.name
        puts n_array
        puts n_array.size
        if nspace.responds_to_name?(n_array[0]) && n_array.size == 1
          puts "returning nspace"
          retn << nspace
        elsif nspace.responds_to_name?(n_array[0])
          nspace._subgroups.each do |name, ns|
            retn += namespace_matches?(ns, n_array[1..-1])
          end
        end
        retn
      end

      retn = []
      if n.empty?
        # An empty array is a corner case, defined as matching all namespaces. Add this namespace, as well as any sub-namespaces this one has.
        retn << self
        self._subgroups.each do |name, namespace|
          retn += namespace.resolve_namespace(n)
        end
      elsif n.first == ':'
        # If the namespace to resolve leads with a colon, then this is an absolute namespace.
        # This is a pretty easy case. First, check that we're in the correct starting namespace, and if so, just walk the namespaces and see if its a match.
        retn += namespace_matches?(self, n[1..-1])
      else
        # If this namespace is a match, then add this namespace to the match.
        # However, we aren't done yet. Since we aren't forcing 1 namespace name per path rule, we have to check all the sub-namespaces.
        # e.g., test:test:test:test is allowed. Not sure why a user would want this, but we aren't stopping it. resolve_namespace(test) would match 4 namespaces there, not one.
        # Additioally, we need to continue checking both the reduced and full namespacs, in case we have something like :test1:test2:test1:test2. For this, :test1:test2 would match both test2s
        # Furthermore, something like: :test1:test2:test1:test2:test2 would match only :test1:test2 and :test1:test2:test1:test2
        # Even further, if this namespace doesn't match, then we still need to check all subsequent namespaces.
        
        if self.responds_to_name?(n.first)
          # See if his namespace matches. Pluck this off and see if the remaining namespaces match
          retn += namespace_matches?(self, n)
        end

        # Keep searching for namespaces with the full nspace array
        self._subgroups.each do |name, namespace|
          retn += namespace.resolve_namespace(n, options)
        end
      end

      puts "---"
      puts retn
      retn
    end

    def responds_to_name?(n)
      name.to_s == n.to_s || aliases.include?(n.to_s)
    end

    def to_console(options={})
      _commands.each do |name, c|
        c.to_console(options)
      end
    end

    # Use :inspect instead of :to_s here since we're actually going to return an array of strings, where the index denotes a line-break.
    # This just saves us from later having to chop the string into newline elements to mess with display widths, etc.
    #def inspect(options={})
      #???
    #end
    
      def with_namespace(namespace, options={}, &block)
        # Check if the namespace exist in the current context. If so, retrieve it, otherwise create it.
        previous_namespace = @current_namespace || self
        @current_namespace = previous_namespace.namespace?(namespace) ? previous_namespace[namespace] : previous_namespace.add_namespace(namespace, options)

        # Run the namespace
        yield @current_namespace

        # reset the namespace after the block ends
        @current_namespace = previous_namespace
      end
      alias_method :with_nspace, :with_namespace

      # Pretty prints the command group
      def pretty_print(options={})
        spacing = options[:spacing] || 0
        top_namespace? ? (puts "#{name} (namespace/provider)") : (puts (' ' * spacing) + "#{name} (namespace)")
        spacing += 2
        _commands.each do |n, cmd|
          puts (' ' * spacing) + "#{n} (command)"
        end
        _subgroups.each do |n, nspace|
          nspace.pretty_print(spacing: spacing + 2)
        end
      end
      alias_method :pp, :pretty_print

    end
  end
end
