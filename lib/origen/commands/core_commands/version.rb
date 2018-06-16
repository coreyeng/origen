Origen.commands.add(:help, :global) do |command|
  # Just support all the different ways applications call 'version'
  command.aliases = ['v', 'ver', '-v', '-ver', '-version', '--v', '--ver', '--version']

  command.option_parser do |opts|
  end
  
  command.body do |cmd|
    if cmd.input_options.key?(:all)
      # The :all option overrides anything else. Just get them all
      Origen.app.gems.each do |gem|
      end
      puts "VERSION!"
    elsif cmd.input_options.empty?
      # No options given, so this is just the standard version command: application, if there is one, followed by origen
      puts "VERSION!"
      puts "app/origen"
    else
      # We'll define the order to be: explicitly listed gems, origen plugins, the application, origen
      # We'll go through these one by one, adding as we go. We'll adjust spacing at the end, if needed

#puts "Application: #{Origen.app.version}" if Origen.app_loaded? && !Origen.running_globally?
#puts "     Origen: #{Origen.version}"

      #Gem::Specification.all.each { |g| puts g.version/name }; nil
      puts "VERSION!"
    end
  end
end

