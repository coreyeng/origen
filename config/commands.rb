# This file should be used to extend origen with application specific tasks

aliases ={

}

@command = aliases[@command] || @command

case @command

when "corey"
  puts "COMMAND TEST!".green

  # Create a test command handler
  handler = Origen::Commands::CommandHandler.new

  # Make a dummy provider and set it as the current provider
  provider = Origen::Commands::Provider.new(name: 'test') do |provider|
    provider.aliases = 't'
  end
  handler.current_provider = provider
  puts "Provider: #{handler.current_provider.name}"
  
  # Add a command
  handler.add(:cmd_from_handler, :shared) do |cmd|
    cmd.aliases = 'cmd_from_handler_alias'
    cmd.body do
      puts "HI from #{cmd.name}!".blue.underline
    end
  end

  # Add a coommand on the provider
  provider.add(:cmd_from_provider, :shared) do |cmd|
    cmd.aliases = 'cmd_from_provider_alias'
    cmd.body do
      puts "HI from #{cmd.name}!".blue.underline
    end
  end

  # Add a namespace with the handler
  #handler.with_namespace(:test, :layer) do |nspace|
  #  nspace.add(:cmd, :shared) do |cmd|
  #    cmd.body do
  #      puts "HI from namespace: #{self.nspace.name}, cmd: #{self.name}"
  #    end
  #  end
  #end

  # Add a namespace on the handler
  handler[:test].with_nspace(:other_layer) do |nspace|
    nspace.aliases = 'ol'
    nspace.add(:cmd, :shared) do |cmd|
      cmd.aliases = 'cmd_alias'
      cmd.body do
        puts "HI from namespace: #{cmd.nspace.name}, cmd: #{cmd.name}".blue.underline
      end
    end
  end

  # Add another provider, command, namepsace, and another command

  handler.pretty_print

  # Call the commands
  puts 'Basic Command Calling'.green
  handler.call('cmd_from_handler')
  handler.call('cmd_from_provider')
  handler.call('cmd')

  puts 'Calling with absolute namespacing'.green
  handler.call(':test:cmd_from_handler')
  handler.call(':test:cmd_from_provider')
  handler.call(':test:other_layer:cmd')

  puts 'Calling with namespacing/provider'.green
  handler.call('test:cmd_from_handler')
  handler.call('test:cmd_from_provider')
  handler.call('test:other_layer:cmd')
  handler.call('other_layer:cmd')

  puts "Calling commands with aliases".green
  handler.call('cmd_from_handler_alias')
  handler.call('cmd_from_provider_alias')
  handler.call('cmd_alias')

  puts "Calling commands with aliases at namespace/provider".green
  handler.call('t:cmd_from_handler')
  handler.call('t:cmd_from_provider')
  handler.call('t:ol:cmd')
  handler.call('t:other_layer:cmd')

  puts "DONE!!".green

  exit 0

when 'corey2'

  # Create a test command handler
  handler = Origen::Commands::CommandHandler.new

  # Make a dummy provider and set it as the current provider
  provider = Origen::Commands::Provider.new(name: 'test') do |provider|
    provider.aliases = 't'
  end
  handler.current_provider = provider

  # Add a command
  handler.add(:cmd_from_handler, :shared) do |cmd|
    cmd.aliases = 'cmd_from_handler_alias'
    cmd.option_parser do |opts|
      opts.on('-p', '--print VAL', 'prints VAL') do |val|
        cmd.input_options[:print] = val
        puts val.cyan.underline
      end
    end
    cmd.body do
      puts "HI from #{cmd.name}!".blue.underline
      puts "  cmd.argv[0]: #{cmd.argv[0]}".blue.underline
      puts cmd.option_parser
      puts "  input_options: #{cmd.input_options.keys.join(',')}".blue.underline
    end
  end
  
  # Make sure programmatic calls work using options and arguments with direct syntax
  puts "Command: #{handler.command('cmd_from_handler').name}"
  puts "Command: #{handler.command('cmd_from_handler').expansions}"
  handler.call('cmd_from_handler working? -p hello')
  
  # Nake sure programmatic calls work using options and arugments with configure syntax
  #handler.get('call_from_handler', print: 'hello').call
  # HMMMM not sure how this should work...
  
  # Expand the command
  handler.command('cmd_from_handler').expand('my_additions') do |ext|
    ext.pre_body do
      puts "PRE-BODY from :my_additions!".green.underline
    end
    ext.post_body do
      puts "POST-BODY! from :my_additions".green.underline
    end
    ext.option_parser do |opts|
      opts.on('--say_hi', 'Says hi') do
        cmd.input_options[:say_hi] = true
        puts "HI!!!!".green.underline
      end
    end
  end
  
  # Query the expansion stuff
#  puts "Expanded: #{handler.expansions}"
  puts "Expanded: #{handler.command('cmd_from_handler').name}".red
  puts "Expanded: #{handler.command('cmd_from_handler').expansions}".yellow
  puts "Expanded: #{handler.expansion('my_additions').expanded_command}"
  puts "Expanded: #{handler.expansion('my_additions').expanded_command.name}"
  
  # Make sure programmatic calls work expanded options and arguments
  handler.call('cmd_from_handler -p hello --say_hi')
  
  # Use the handler's expand method
  handler.expand('cmd_from_handler', 'my_other_additions') do |exp|
    exp.pre_body do 
      puts "PRE-BODY from :my_other_additions!"
    end
  end
  
  # Add an expansions at a namespace
  handler.with_nspace('cmd_expansions') do |nspace|
    handler.expand('cmd_from_handler', 'my_nspace_additions') do |exp|
      exp.pre_body do 
        puts "PRE-BODY from :my_nspace_additions!"
      end
    end
  end

  puts "All handler expansions: #{handler.expansions}"
  
  puts "DONE!!".green

  exit 0

when "corey_help"
  exit 0

when "corey_version"
  puts 'Try the standard version command'.green
  handler.call(':origen:version')
  
  puts 'Try the aliases'.green
  handler.call('v')
  handler.call('ver')
  handler.call('-v')
  handler.call('-ver')
  handler.call('-version')
  handler.call('--v')
  handler.call('--ver')
  handler.call('--version')
  
  puts 'Try the namespacing'.green
  handler.call(':origen:v')
  handler.call(':origen:ver')
  handler.call(':origen:-v')
  handler.call(':origen:-ver')
  handler.call(':origen:-version')
  handler.call(':origen:--v')
  handler.call(':origen:--ver')
  handler.call(':origen:--version')
  
  puts 'Get the version of a plugin'.green
  handler.call('version origen')
  handler.call('version nokogiri json')
  handler.call('version -a') # All dependencies, basically bundler
  handler.call('version --app') # shows the application
  handler.call('version --plugins') # shows the Origen plugin versions
  handler.call('version -o') # shows the Origen version
  
  exit 0

when "tags"
  Dir.chdir Origen.root do
    system "ripper-tags --recursive lib"
  end
  exit 0

when "specs"
  require "rspec"
  exit RSpec::Core::Runner.run(['spec'])

when "examples", "test"  
  Origen.load_application
  status = 0
  Dir["#{Origen.root}/examples/*.rb"].each do |example|
    require example
  end
  
  if Origen.app.stats.changed_files == 0 &&
     Origen.app.stats.new_files == 0 &&
     Origen.app.stats.changed_patterns == 0 &&
     Origen.app.stats.new_patterns == 0

    Origen.app.stats.report_pass
  else
    Origen.app.stats.report_fail
    status = 1
  end
  puts
  if @command == "test"
    Origen.app.unload_target!
    require "rspec"
    result = RSpec::Core::Runner.run(['spec'])
    status = status == 1 ? 1 : result
  end
  exit status

when "regression"
  # You must tell the regression manager up front what target will be run within
  # the block
  options[:targets] = %w(debug v93k jlink)
  Origen.regression_manager.run(options) do |options|
    Origen.lsf.submit_origen_job "generate j750.list -t debug --plugin origen_core_support"
    Origen.lsf.submit_origen_job "generate v93k_workout -t v93k --plugin none"
    Origen.lsf.submit_origen_job "generate dummy_name port -t debug --plugin none"
    Origen.lsf.submit_origen_job "generate jlink.list -t jlink --plugin none"
    Origen.lsf.submit_origen_job "compile templates/test/set3 -t debug --plugin none"
    Origen.lsf.submit_origen_job "compile templates/test/inspections.txt.erb -t debug --plugin none"
    Origen.lsf.submit_origen_job "program program -t debug --plugin none"
    Origen.lsf.submit_origen_job "program program -t debug --doc --plugin none"
  end
  exit 0

when "make_file"
  Origen.load_application
  system "touch #{Origen.root}/#{ARGV.first}"  
  exit 0

else
  @application_commands = <<-EOT
 specs        Run the specs (unit tests), -c will enable coverage
 examples     Run the examples (acceptance tests), -c will enable coverage
 test         Run both specs and examples, -c will enable coverage
 regression   Test the regression manager (runs a subset of examples)
 tags         Generate ctags for this app
  EOT

end 
