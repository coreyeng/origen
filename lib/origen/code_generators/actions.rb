require 'open-uri'
require 'rbconfig'

module Origen
  module CodeGenerators
    module Actions
      def initialize(*args) # :nodoc:
        if args.last.is_a?(Hash)
          @config = args.last.delete(:config) || {}
        end
        super
        @in_group = nil
      end

      def config
        @config
      end

      # Removes (comments out) the specified configuration setting from +config/application.rb+
      #
      #   comment_config :semantically_version
      def comment_config(*args)
        options = args.extract_options!
        name = args.first.to_s

        # Set the message to be shown in logs
        log :comment, name

        file = File.join(Origen.root, 'config', 'application.rb')
        comment_lines(file, /^\s*config.#{name}\s*=.*\n/)
      end

      # Adds an entry into +config/application.rb+
      def add_config(*args)
        options = args.extract_options!
        name, value = args

        # Set the message to be shown in logs
        message = name.to_s
        if value ||= options.delete(:value)
          message << " (#{value})"
        end
        log :insert, message

        file = File.join(Origen.root, 'config', 'application.rb')
        value = quote(value) if value.is_a?(String)
        value = ":#{value}" if value.is_a?(Symbol)
        insert_into_file file, "  config.#{name} = #{value}\n\n", after: /^\s*class.*\n/
      end

      # Adds an entry into +Gemfile+ for the supplied gem.
      #
      #   gem "rspec", group: :test
      #   gem "technoweenie-restful-authentication", lib: "restful-authentication", source: "http://gems.github.com/"
      #   gem "rails", "3.0", git: "git://github.com/rails/rails"
      def gem(*args)
        options = args.extract_options!
        name, version = args

        # Set the message to be shown in logs. Uses the git repo if one is given,
        # otherwise use name (version).
        parts, message = [quote(name)], name
        if version ||= options.delete(:version)
          parts << quote(version)
          message << " (#{version})"
        end
        message = options[:git] if options[:git]

        log :gemfile, message

        options.each do |option, value|
          parts << "#{option}: #{quote(value)}"
        end

        in_root do
          str = "gem #{parts.join(', ')}"
          str = '  ' + str if @in_group
          str = "\n" + str
          append_file 'Gemfile', str, verbose: false
        end
      end

      # Wraps gem entries inside a group.
      #
      #   gem_group :development, :test do
      #     gem "rspec-rails"
      #   end
      def gem_group(*names, &block)
        name = names.map(&:inspect).join(', ')
        log :gemfile, "group #{name}"

        in_root do
          append_file 'Gemfile', "\ngroup #{name} do", force: true

          @in_group = true
          instance_eval(&block)
          @in_group = false

          append_file 'Gemfile', "\nend\n", force: true
        end
      end

      # Add the given source to +Gemfile+
      #
      #   add_source "http://gems.github.com/"
      def add_source(source, _options = {})
        log :source, source

        in_root do
          prepend_file 'Gemfile', "source #{quote(source)}\n", verbose: false
        end
      end

      # Adds a line inside the Application class for <tt>config/application.rb</tt>.
      #
      # If options <tt>:env</tt> is specified, the line is appended to the corresponding
      # file in <tt>config/environments</tt>.
      #
      #   environment do
      #     "config.autoload_paths += %W(#{config.root}/extras)"
      #   end
      #
      #   environment(nil, env: "development") do
      #     "config.autoload_paths += %W(#{config.root}/extras)"
      #   end
      def environment(data = nil, options = {})
        sentinel = /class [a-z_:]+ < Rails::Application/i
        env_file_sentinel = /Rails\.application\.configure do/
        data = yield if !data && block_given?

        in_root do
          if options[:env].nil?
            inject_into_file 'config/application.rb', "\n    #{data}", after: sentinel, verbose: false
          else
            Array(options[:env]).each do |env|
              inject_into_file "config/environments/#{env}.rb", "\n  #{data}", after: env_file_sentinel, verbose: false
            end
          end
        end
      end
      alias_method :application, :environment

      # Run a command in git.
      #
      #   git :init
      #   git add: "this.file that.rb"
      #   git add: "onefile.rb", rm: "badfile.cxx"
      def git(commands = {})
        if commands.is_a?(Symbol)
          run "git #{commands}"
        else
          commands.each do |cmd, options|
            run "git #{cmd} #{options}"
          end
        end
      end

      # Create a new file in the lib/ directory. Code can be specified
      # in a block or a data string can be given.
      #
      #   lib("crypto.rb") do
      #     "crypted_special_value = '#{rand}--#{Time.now}--#{rand(1337)}--'"
      #   end
      #
      #   lib("foreign.rb", "# Foreign code is fun")
      def lib(filename, data = nil, &block)
        log :lib, filename
        create_file("lib/#{filename}", data, verbose: false, &block)
      end

      # Create a new +Rakefile+ with the provided code (either in a block or a string).
      #
      #   rakefile("bootstrap.rake") do
      #     project = ask("What is the UNIX name of your project?")
      #
      #     <<-TASK
      #       namespace :#{project} do
      #         task :bootstrap do
      #           puts "I like boots!"
      #         end
      #       end
      #     TASK
      #   end
      #
      #   rakefile('seed.rake', 'puts "Planting seeds"')
      def rakefile(filename, data = nil, &block)
        log :rakefile, filename
        create_file("lib/tasks/#{filename}", data, verbose: false, &block)
      end

      # Generate something using a generator from Rails or a plugin.
      # The second parameter is the argument string that is passed to
      # the generator or an Array that is joined.
      #
      #   generate(:authenticated, "user session")
      def generate(what, *args)
        log :generate, what
        argument = args.flat_map(&:to_s).join(' ')

        in_root { run_ruby_script("bin/rails generate #{what} #{argument}", verbose: false) }
      end

      # Runs the supplied rake task
      #
      #   rake("db:migrate")
      #   rake("db:migrate", env: "production")
      #   rake("gems:install", sudo: true)
      def rake(command, options = {})
        log :rake, command
        env  = options[:env] || ENV['RAILS_ENV'] || 'development'
        sudo = options[:sudo] && RbConfig::CONFIG['host_os'] !~ /mswin|mingw/ ? 'sudo ' : ''
        in_root { run("#{sudo}#{extify(:rake)} #{command} RAILS_ENV=#{env}", verbose: false) }
      end

      # Reads the given file at the source root and prints it in the console.
      #
      #   readme "README"
      def readme(path)
        log File.read(find_in_source_paths(path))
      end

      protected

      # Define log for backwards compatibility. If just one argument is sent,
      # invoke say, otherwise invoke say_status. Differently from say and
      # similarly to say_status, this method respects the quiet? option given.
      def log(*args)
        if args.size == 1
          say args.first.to_s unless options.quiet?
        else
          args << (behavior == :invoke ? :green : :red)
          say_status(*args)
        end
      end

      # Add an extension to the given name based on the platform.
      def extify(name)
        if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
          "#{name}.bat"
        else
          name
        end
      end

      # Surround string with single quotes if there is no quotes.
      # Otherwise fall back to double quotes
      def quote(value)
        return value.inspect unless value.is_a? String

        if value.include?("'")
          value.inspect
        else
          "'#{value}'"
        end
      end
    end
  end
end
