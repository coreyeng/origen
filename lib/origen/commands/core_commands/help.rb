puts Origen.commands
Origen.commands.add(:help, :app) do |command|
  command.body do
    puts 'Welcome to Origen: The Semiconductor Developer\'s Kit'
    puts 'Also see: http://origen-sdk.org/'
    puts
    puts 'Below is a listing of the available commands and namespaces.'
    puts "Each command and namespace can be run with '-h' for further information."
    puts "To see more information on the help command, run: origen :origen:help -h"
    puts

    # By default, this command only provides the first level of commands
    puts "For a full command listing, run: origen :origen:help --complete"
    
    puts 'The following are provided by the Origen Core:'
    Origen.commands[:origen].to_console(scope: :shared, level: 1)
    puts
    
    puts 'The following are shared by various plugins for use in applications:'
    Origen.commands.shared_providers.each { |provider| Origen.commands[provider_name].to_console(scope: :shared, level: 1) }
    puts

    puts Origen.commands.top_namespaces

    puts 'The following are available only to this application:'
    Origen.commands[Origen.commands.application_provider.name].to_console(scope: :application, level: 1)
    puts
    
    puts 'The following are shared by various plugins available globally:'
    Origen.commands.global_providers.each { |provider| Origen.commands.to_console(provider.name, :global) }
    puts

    if false #Origen.mode.test?
      puts 'The following are Origen self-test commands:'
      Origen.commands.test_providers.each { |provider| Origen.commands.to_console(provider.name, :test) }
      puts
    end
  end
  command.aliases =  ['-h', '--help', '-help', 'h']
end

Origen::Commands.with_nspace(:help) do |nspace|
  nspace.aliases = 'h'

  Origen.commands.add_shared_cmd(:command) do |command|
    command.body do
      puts 'COMMAND helper!'.green
    end
    command.aliases = 'cmd'
  end

  Origen.commands.add_shared_cmd(:namespace) do |command|
    command.body do
      puts 'NAMESPACE helper!'.green
    end
    command.aliases = ['nspace', 'ns']
  end

  Origen.commands.add_shared_cmd(:provider) do |command|
    command.body do
      puts 'PROVIDER helper'.green
    end
    command.help [
      'Shows the namespaces and commands only from the specified provider(s)',
      'Also shows the version of the provider currently used.',
    ]
    command.aliases = ['plugin', 'pl', 'app', 'application']
  end
end

=begin
Origen.commands.add_shared_cmd(:version) do |command|
  command.body do
    puts 'VERSION helper!'
  end

  # Different tools have different ways of calling 'version.' Just support all of them.
  command.aliases = ['v', 'ver', '-v', '-ver', '-version', '--v', '--ver', '--version']
end

Origen.with_cmd_nspace(:version) do |nspace|
  nspace.aliases = ['ver', 'v']
end
=end

