require 'origen/commands/command_group'
require 'origen/commands/command'

module Origen

  #class Commands
  module Commands
    self.instance_variable_set(:@top_namespaces, {}.with_indifferent_access)

    # Base provder for adding commands not from a plugin (e.g., specs tests, dynamic commands)
    # This is also a namespace. 
    class Provider < Origen::Commands::CommandGroup
      attr_reader :name
      attr_accessor :command_handler

      def initialize(options={}, &block)
        @name = options[:name] || "dummy_provider_#{object_id}"
        super(name, self, self, options, &block)
      end
    end

    class CommandHandler
      attr_reader :top_namespaces
      attr_reader :current_provider
      attr_reader :current_namespace

      def initialize(options={})
        @top_namespaces = {}.with_indifferent_access
      end
      
      # Returns a list of expansions available, as a hash.
      # Keys are the namespace/name of the expansions, value is the expansions itself.
      # Note: this returns a flattened hash.
      # TODO: Implement
      def expansions(options={})
      end

      def current_provider=(provider)
        provider.command_handler = self
        @current_provider = provider
      
        # Switch the namespace to this new provider. Either retreive the current namespace, or create a new one.
        #@top_namespaces[provider.name] = Origen::Commands::CommandGroup.new(provider.name, provider, provider) unless @top_namespaces.key?(provider.name)
        #@current_namespace = @top_namespaces[provider.name]
        @top_namespaces[provider.name] = @current_provider
        @current_namespace = @current_provider

        provider
      end

      def providers(options={})
        if options[:scope] == :shared
          @top_namespaces.select { |name, nspace| nspace.shared_commands? }
        elsif options[:scope] == :global
          @top_namespaces.select { |name, nspace| nspace.global_commands? }
        elsif options[:scope] == :application
          app_provider
        elsif options[:scope] == :test
          @top_namespaces.select { |name, nspace| nspace.test_commands? }
        elsif options[:scope].nil?
          @top_namespaces
        else
          fail "Unknown scope #{scope}"
        end
      end

      def shared_providers
        providers(scope: :shared)
      end

      def test_providers
        providers(scope: :test)
      end

      def global_providers
        providers(scope: :global)
      end

      def application_providers
        providers(scope: :application)
      end
      alias_method :application_provider, :application_providers

      def command(cmd, options={}, &block)
        resolve(cmd)
      end

      def expansion(exp, options={})
        ex = top_namespaces.collect { |n, nspace| nspace.resolve_expansion(exp) }.flatten
        return ex.first if ex.size == 1
        fail("More than one or no expansion found")
      end

      # Resolves the command string back to the command instance.
      # Returns the command instance if its found, or false if not.
      def resolve(command, options={})
        # Begin by going through each command and seeing if the command fits.
        # The command itself will evaulate based on its namespace, namespace aliases, and namespace selectors applied.
        # NOTE: at this point its okay to have more than one matching command.
        puts "Commands".green
        puts command
        cmds = top_namespaces.collect { |n, nspace| nspace.resolve_command(command) }.flatten
        puts cmds
        puts cmds.first.name.cyan
        # If we only have one remaining command, then that's it. Return it.
        return cmds.first if cmds.size == 1
        
        # NOTE: even though we could have loaded the commands taking into the application and current plugin, the commands are technically always available and can be run at any time.
        # So, need to keep in mind that he user could arbirarily create new commands, so for safety, just build the list assuming its out of order and widdle it down to one here.
        app = '?'
        plugin = '?'
        cmd = cmds.select { |cmd| cmd.provider == app }
        return cmd.first if cmd.size == 1

        cmd = cmds.select { |cmd| cmd.provider == plugin }
        return cmd.first if cmd.size == 1

        puts "CMDs: #{cmds}"

        # If multiple commands are still found, declare this ambigous and complain.
        puts "Ambiguous command name encountered: #{name}"
        puts 'Unable to resolve these commands:'
        cmds.each do |cmd|
          puts "  #{cmd.absolute_name}"
          puts "    Namespace Aliases: #{cmd.namespace_aliases.join(', ')}"
          puts "    Provider By: #{cmd.provider.name}"
        end
        puts 'Please try again with appropriate namespacing'
        puts "(current application: #{app})"
        puts "(current plugin: #{plugin})"
        fail
      end

      def call(cmd_str, options={})
        argv = cmd_str.split(' ')
        cmd = argv.shift
        cmd = resolve(cmd)
        #puts "Calling: #{cmd.name}"
        if cmd
          cmd.launch(argv: argv)
        else
          puts "Error: Command not recognized: #{command}".red
          puts
          help!
        end
      end

      def add(command, scope, options={}, &block)
        #if current_namespace.nil?
        #  fail 'No current namespace is set!'
        #end

        #if current_provider.nil?
        #  fail 'No current provider is set!'
        #end

        if command.is_a?(Origen::Commands::Command)
          fail 'Not supported yet'
        else
          options[:namespaces] = [@current_namespace]
          options[:provider] = current_provider
          @current_namespace.add_command(command.to_s, scope, options, &block)
          puts "Adding command: #{command}".green
        end
      end

      # TODO: figure out WTF this should do...
      def with_namespace(provider, options={}, &block)
        if has_provider?(provider)
          providers[provider].with_namespace(nspace, options, &block)
        else
          fail "No provider #{provider}"
        end
      end
      alias_method :with_nspace, :with_namespace

      def has_provider?(provider)
        top_namespaces.key?(provider)
      end

      def [](nspace)
        top_namespaces[nspace]
      end

      # Pretty printing a command handler is really just calling pretty print on each top namespaces
      def pretty_print(options={})
        top_namespaces.each do |name, command_group|
          #puts "#{name} (provider)"
          command_group.pretty_print
        end
      end

    end

    # Althogh multiple handlers could, in theory, be running around (e.g., during specs testing), we'll force a single command handler at the Origen::Commands level
    # that Origen will use. There can be 50 other command handlers sitting in memory, Origen will only use this one.
    # This is the same as a normal command group but with some added methods to collect the commands from Origen and its plugins.
    class << self
      attr_reader :commands
      attr_reader :top_namespaces
      attr_reader :current_provider
      attr_reader :current_namespace
      #attr_reader :current_namespace

=begin
      def with_namespace(namespace, options={}, &block)
        # Check if the namespace exist in the current context. If so, retrieve it, otherwise create it.
        previous_namespace = @current_namespace
        @current_namespace = previous_namespace.namespace?(namespace) ? previous_namespace[namespace] : previous_namespace.add_namespace(namespace, options)

        # Run the namespace
        yield @current_namespace

        # reset the namespace after the block ends
        @current_namespace = previous_namespace
      end
      alias_method :with_nspace, :with_namespace
=end
    #def with_command_group(grp, options={}, &block)
    #  yield
    #end

    def clear!
      @top_namespaces = {}.with_indifferent_access
    end



    def to_console(options={})
    end

    def app_provider
      Origen.app.class
    end

    def collect_commands
      # Commands are collected the same as before.
      # LEGACY: collection is setup so that the legacy can be axed at any time, but this does result in the command launchers in the plugins/applications
      # being run twice.
      # The exception to this are Origen's core commands, which are loaded differently.

      # To keep track of the plugin namespace, we'll set an instance variable that shows the current plugin we're evaluating. This will be the namespace of the command.
      # We'll update this as we go.
      #@current_namespace = 'origen'
      @current_provider = Origen
      #@current_group = Origen::CommandGroup.new(@current_namespace, @provider, @provider)
      @current_namespace = Origen::CommandGroup.new('origen', current_provider, current_provider)
      top_namespaces['origen'] = @current_namespace
      require 'origen/commands/help'
      
      # Load the OrigenCoreApplication commands. This allows the non-core commands to behave like any other aplication.
      #require Origen.top.join("config/application")
      #require OrigenCoreApplication.command_launcher
      # If the namespace is still undefined (nil) then no commands for the application were found. That's fine, but we need to add a placeholder so that
      # the application commands will return an empty namespace instead of nil.
      current_provider = Origen.app.class
      @current_namespace = Origen::CommandGroup.new(Origen.app.class.name, current_provider, current_provider)
      top_namespaces[Origen.app.class.name] = @current_namespace
      require Origen.app.root.join('config/application')
      if Origen.app.has_command_launcher?
        require Origen.app.command_launcher
      end
      
      # Load the remaining plugins.

      # Set the instance variables to nil.
      # This implies that collect_commands has finished and automated setup is completed.
      # This affects how commands added dynamically are done.
      @current_namespace = nil
      @current_provider = nil
      #@current_group = nil
    end

    def check_namespaces(namespace, options={})
    end

      # Prints the help message to the terminal.
      def help!(options={})
        # Safeguard here. During development and if any extra work needs to be done, failure to resolve commands gets the massive recurssive stack trace.
        # Make sure the help command resolves first.
        if resolve(':origen:help')
          # Force the call to Origen's help command, even if something else overrode it.
          self.call(':origen:help')
        else
          fail 'Could not resolve Origen help command. No help message provided.'
        end
      end
    end
  end

  # Create the commands handler at core level.
  class << self
    # :commands by itself will list all the available commands.
    # :commands(cmd=...) will act as an accessor

    def commands(cmd=nil)
      #return @commands if @commands
      #@commands = Commands.new()
      Origen::Commands
    end

    #Origen::Commands.collect_commands
  end
end

# Create the commands
# NOTE FOR LEGACY: the command handler will be created first so that Origen will go through its standard 'boot process'
# (collecting commands, etc.)
# But before any command from command handler is, the legacy command launcher will be run.
# If we get through the legacy command launcher, then the command handler will take over.
# NOTE 1: this means that legacy commands will have priority over the command handler.
# NOTE 2: the else case is also taken over.
# - Corey
#puts "Commands Interface: #{Origen.commands.commands}"

#Origen::Commands.call(ARGV[0])

#exit!

# Main entry point for all Origen commands, some global option handling
# is done here (i.e. options that apply to all commands) before handing
# over to the specific command handlers
require 'optparse'

ARGV << '--help' if ARGV.empty?

ORIGEN_COMMAND_ALIASES = {
  'g'         => 'generate',
  'p'         => 'program',
  't'         => 'target',
  '-t'        => 'target',          # For legacy reasons
  'e'         => 'environment',
  '-e'        => 'environment',
  'l'         => 'lsf',
  'i'         => 'interactive',
  'c'         => 'compile',
  'pl'        => 'plugin',
  '-v'        => 'version',
  '--version' => 'version',
  '-version'  => 'version',
  'm'         => 'mode'
}

@command = ARGV.shift
@command = ORIGEN_COMMAND_ALIASES[@command] || @command
@global_commands = []

# Moved here so boot.rb file can know the current command
Origen.send :current_command=, @command

# Don't log to file during the save command since we need to preserve the last log,
# this is done as early in the process as possible so any deprecation warnings during
# load don't trigger a new log
Origen::Log.console_only = (%w(save target environment version).include?(@command) || ARGV.include?('--exec_remote'))

if ARGV.delete('--coverage') ||
   ((@command == 'specs' || @command == 'examples' || @command == 'test') && (ARGV.delete('-c') || ARGV.delete('--coverage')))
  require 'simplecov'
  begin
    if ENV['CONTINUOUS_INTEGRATION']
      require 'coveralls'
      SimpleCov.formatter = Coveralls::SimpleCov::Formatter
    end
  rescue LoadError
    # No problem
  end
  SimpleCov.start
  Origen.log.info 'Started code coverage'
  SimpleCov.configure do
    filters.clear # This will remove the :root_filter that comes via simplecov's defaults
    add_filter do |src|
      !(src.filename =~ /^#{Origen.root}\/lib/)
    end

    # Results from commands run in succession will be merged by default
    use_merging(!ARGV.delete('--no_merge'))

    # Try and make a guess about which directory contains the bulk of the application's code
    # and create groups to match the main folders
    d1 = "#{Origen.root}/lib/#{Origen.app.name.to_s.underscore}"
    d2 = "#{Origen.root}/lib/#{Origen.app.namespace.to_s.underscore}"
    d3 = "#{Origen.root}/lib"
    if File.exist?(d1) && File.directory?(d1)
      dir = d1
    elsif File.exist?(d2) && File.directory?(d2)
      dir = d2
    else
      dir = d3
    end

    Dir.glob("#{dir}/*").each do |d|
      d = Pathname.new(d)
      if d.directory?
        add_group d.basename.to_s.camelcase, d.to_s
      end
    end

    command_name @command

    path_to_coverage_report = Pathname.new("#{Origen.root}/coverage/index.html").relative_path_from(Pathname.pwd)

    at_exit do
      SimpleCov.result.format!
      puts ''
      puts 'To view coverage report:'
      puts "  firefox #{path_to_coverage_report} &"
      puts ''
    end
  end
end

require 'origen/global_methods'
include Origen::GlobalMethods

Origen.lsf.current_command = @command

if ARGV.delete('-d') || ARGV.delete('--debug')
  begin
    if RUBY_VERSION >= '2.0.0'
      require 'byebug'
    else
      require 'rubygems'
      require 'ruby-debug'
    end
  rescue LoadError
    def debugger
      caller[0] =~ /.*\/(\w+\.rb):(\d+).*/
      puts 'The debugger gem is not installed, add the following to your Gemfile:'
      puts
      puts "if RUBY_VERSION >= '2.0.0'"
      puts "  gem 'byebug', '~>3.5'"
      puts 'else'
      puts "  gem 'debugger', '~>1.6'"
      puts 'end'
      puts
    end
  end
  Origen.enable_debugger
else
  def debugger
    caller[0] =~ /.*\/(\w+\.rb):(\d+).*/
    puts "#{Regexp.last_match[1]}:#{Regexp.last_match[2]} - debugger statement ignored, run again with '-d' to enable it"
  end
end

if ARGV.include?('-verbose') || ARGV.include?('--verbose')
  options ||= {}
  Origen.log.level = :verbose
  ARGV.delete('-verbose')
  ARGV.delete('--verbose')
end

if ARGV.include?('-silent') || ARGV.include?('--silent')
  options ||= {}
  Origen.log.level = :silent
  ARGV.delete('-silent')
  ARGV.delete('--silent')
end

# If the current command is an LSF execution request (that is a request to
# execute a non-Origen command remotely)
if (@command == 'lsf' || @command == 'l') && (ARGV.include?('-e') || ARGV.include?('--execute'))
  # Don't apply these global options yet, pass them through to the underlying command
else
  if ARGV.delete('--profile')
    # This means that as well as applying to the current thread, this option will also
    # be applied to any remote jobs triggered by this thread
    Origen.app.lsf_manager.add_command_option('--profile')
    Origen.enable_profiling
  end
  if ARGV.delete('--exec_remote') && @command != 'lsf' && @command != 'l'
    Origen.running_remotely = true
  end
  # Set the Origen operating mode if supplied
  ix = ARGV.index('-m') || ARGV.index('--mode')
  if ix
    ARGV.delete_at(ix)
    mode = ARGV[ix]
    ARGV.delete_at(ix)
    Origen.app.lsf_manager.add_command_option('--mode', mode)
    Origen.mode = mode
    # Make sure this sticks for the remainder of this thread
    Origen.mode.freeze
  end
end

# Give application commands the first shot at executing the given command,
# the application file must exit upon servicing the command if it wants to
# prevent Origen from then having a go.
# This order is preferable to allowing Origen to go first since it allows
# overloading of Origen commands by the application.
@application_options = []
@plugin_commands = []
# Prevent plugins from being able to accidentally override app commands
# @application_commands = []
app_id = @application_options.object_id
plugin_id = @plugin_commands.object_id
# Prevent plugins from being able to accidentally override app commands
# app_cmd_id = @application_commands.object_id
app_opt_err = false
plugin_opt_err = false
app_cmd_err = false
if File.exist? "#{Origen.root}/config/commands.rb"
  require "#{Origen.root}/config/commands"
  if @application_options.object_id != app_id
    Origen.log.warning "Don't assign @application_options to a value in config/commands.rb!"
    Origen.log.warning 'Do something like this instead:'
    Origen.log.warning '  @application_options << ["-v", "--vector_comments", "Add the vector and cycle number to the vector comments"]'
    app_opt_err = true
  end
  if @plugin_commands.object_id != plugin_id
    Origen.log.warning "Don't assign @plugin_commands to a new value in config/commands.rb!"
    Origen.log.warning 'Do something like this instead:'
    Origen.log.warning '  @plugin_commands << " testers:build   Build a test program from a collection of sub-programs"'
    plugin_opt_err = true
  end
end
# Only the app can set this, so cache it locally prevent any plugins overriding it
application_commands = @application_commands || ''

shared_commands = Origen.app.plugins.shared_commands
if shared_commands && shared_commands.size != 0
  shared_commands.each do |file|
    require file
    if @application_options.object_id != app_id && !app_opt_err
      Origen.log.warning "Don't assign @application_options to a new value in #{file}!"
      Origen.log.warning 'Do something like this instead:'
      Origen.log.warning '  @application_options << ["-v", "--vector_comments", "Add the vector and cycle number to the vector comments"]'
      app_opt_err = true
    end
    if @plugin_commands.object_id != plugin_id && !plugin_opt_err
      Origen.log.warning "Don't assign @plugin_commands to a new value in #{file}!"
      Origen.log.warning 'Do something like this instead:'
      Origen.log.warning '  @plugin_commands << " testers:build   Build a test program from a collection of sub-programs"'
      plugin_opt_err = true
    end
  end
end

# Get a list of registered plugins and get the global launcher
@global_launcher = Origen._applications_lookup[:name].dup.map do |plugin_name, plugin|
  shared = plugin.config.shared || {}
  if shared[:global_launcher]
    file = "#{plugin.root}/#{shared[:global_launcher]}"
    require file
    file
  end
end.compact

case @command
when 'generate', 'program', 'compile', 'merge', 'interactive', 'target', 'environment',
     'save', 'lsf', 'web', 'time', 'dispatch', 'rc', 'lint', 'plugin', 'fetch', 'mode', 'gem' # , 'add'

  require "origen/commands/#{@command}"
  exit 0 unless @command == 'interactive'

when 'exec'
  load ARGV.first
  exit 0

when 'version'
  Origen.app # Load app
  require 'origen/commands/version'
  exit 0

else
  if ['-h', '--help'].include?(@command)
    status = 0
  else
    puts "Error: Command not recognized: #{@command}"
    status = 1
  end
  puts <<-EOT
Usage: origen COMMAND [ARGS]

The core origen commands are:
  EOT
  cmds = <<-EOT
 environment  Display or set the environment (short-cut alias: "e")
 target       Display or set the target (short-cut alias: "t")
 mode         Display or set the mode (short-cut alias: "m")
 plugin       Display or set the plugin (short-cut alias: "pl")
 generate     Generate a test pattern (short-cut alias: "g")
 program      Generate a test program (short-cut alias: "p")
 interactive  Start an interactive Origen console (short-cut alias: "i")
 compile      Compile a template file or directory (short-cut alias: "c")
 exec         Execute any Ruby file with access to your app environment

 rc           Revision control commands, see -h for details
 save         Save the new or changed files from the last run or a given log file
 lsf          Monitor and manage LSF jobs (short-cut alias: "l")
 web          Web page tools, see -h for details
 time         Tools for test time analysis and forecasting
 lint         Lint and style check (and correct) your application code
  EOT
  cmds.split(/\n/).each do |line|
    puts Origen.clean_help_line(line)
  end
  puts
  if @application_commands && !@application_commands.empty?
    puts 'In addition to these the application has added:'
    @application_commands.split(/\n/).each do |cmds|
      cmds.split(/\n/).each do |line|
        puts Origen.clean_help_line(line)
      end
    end
    puts
  end

  if @plugin_commands && !@plugin_commands.empty?
    puts 'The following commands are provided by plugins:'
    @plugin_commands.each do |cmds|
      cmds.split(/\n/).each do |line|
        puts Origen.clean_help_line(line)
      end
    end
    puts
  end

  if @global_launcher && !@global_launcher.empty?
    puts 'The following global commands are provided by plugins:'
    @global_commands.each do |cmds|
      cmds.split(/\n/).each do |line|
        puts Origen.clean_help_line(line)
      end
    end
    puts
  end

  puts <<-EOT
All commands can be run with -d (or --debugger) to enable the debugger.
All commands can be run with --coverage to enable code coverage.
Many commands can be run with -h (or --help) for more information.

  EOT

  puts Origen.commands
  #Origen.commands.help!

  #exit status
end
