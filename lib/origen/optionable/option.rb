module Origen
  module Optionable
  
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
      attr_reader :default_is_proc
      attr_reader :default_description
      attr_reader :required
      
      BOOLEAN = [true, false, TrueClass, FalseClass]
      
      ACCEPTED_OPTIONS = {
        description: [String, Array],
        default: nil,
        #doc_group:
        accepted_classes: [Class, Array],
        accepted_values: nil,
        accepted_checker: [Proc],
        required: BOOLEAN + [Proc],
        default_is_nil: BOOLEAN,
        default_is_proc: BOOLEAN,
        default_description: [String, Array],
      }
      
      def initialize(name, options={})
        @name = name
        @has_been_set = false
        
        validate_self(options)
        
        if options[:default]
          #if options[:default].is_a?(Proc) && @default_is_proc != true
          #  @default = options[:default].call(self, @parent)
          #else
          #  @default = options[:default]
          #end
          #set_default_value(options[:default]) if options[:default]
          begin
            #validate_input(options[:default])
          rescue Exception => e
            # Catch any issues with the given default value and prepend a note
            # stating that this occured when trying to set the default.
            raise e, "Error in option #{name} when setting default value: " + e.message
          end
          @current_value = @default
          @has_been_set = true
          @has_been_set_by_default = true
        end
        @required = options[:required] || false
        
        if @default_is_nil
          @current_value = nil
          @has_been_set = true
          @has_been_set_by_default = true
        end
        
        # Check that extra options weren't provided
        #unless (options.keys - ACCEPTED_OPTIONS.keys).empty?
        #  raise Error, "Option class cannot accept parameter(s): #{(options.keys - ACCEPTED_OPTIONS.keys).join(',')}"
        #end
      end
      
      def set(value)
        validate_input(value)
        @current_value = value
        @has_been_set = true
        @set_by_user = true
      end
      
      def has_been_set_by_user?
        @set_by_user
      end
      
      def has_been_set?
        @has_been_set
      end
      
      def set_by_default?
        @set_by_default
      end
      
      # Checks to see if a default value is available. If so, sets it.
      def _set_default(options={})
        if !@default.nil?
          # default is anything except nil (including false). If the default is a Proc and default_is_proc is false,
          # then run the Proc to set the default.
          if @default.is_a?(Proc) && !@default_is_proc
            # Run the proc to get the value, check that it meets any given criteria, and set the current value.
          else
            # Check that the default meets any given criteria and set the current value.
          end
        elsif @default_is_nil
          @current_value = nil
          @set_by_default = true
        end
      end
      
      def value
        _set_default
        unless has_been_set?
          raise UnsetValueError, "Tried to retrieve the value for option '#{name}' but it has not been set yet nor has a default value!"
        end
        current_value
      end
      
      def validate_input(value)
        unless accepted_classes.nil?
          unless accepted_classes.include?(value.class)
            raise UnacceptedClassError, "Value's class '#{value.class}' is not accepted for option '#{name}'. Accepted classes are: #{accepted_classes}"
          end
        end
        
        unless accepted_checker.nil?
          begin
            pass_fail_result = @accepted_checker.call(value)
            if pass_fail_result != true && pass_fail_result != false
              raise Error, ":accepted_checker proc did not return a true or false value! Received value: #{pass_fail_result} Of class: #{pass_fail_result.class}"
            end
            unless pass_fail_result
              raise AcceptedCheckerFailed
            end
          rescue Origen::Optionable::AcceptedCheckerFailed => e
            # Expect this to a value thrown by the checker. Rethrow it. If it has a custom message, use that
            # instead.
            if e.message != "Origen::Optionable::AcceptedCheckerFailed"
              raise e
            else
              raise AcceptedCheckerFailed, "Value '#{value}' failed to pass the given checker!"
            end
          rescue Origen::Optionable::Error => e
            # These are also expected. Rethrow these without any intervention
            raise e
          rescue Exception => e
            # Something else went wrong when trying to run the AcceptedChecker.
            # Prepend to the error stating that this occured when running the checker and rethrow the error
            raise e, "Error when running checker for option #{@name}: " + e.message
          end
        end
        
        unless accepted_values.nil?
          unless accepted_values.include?(value)
            raise UnacceptedValueError, "Value '#{value}' is not accepted for option '#{name}'. Accepted values are: #{accepted_values}"
          end
        end
      end
            
      def validate_self(options)
        options.each do |opt, value|
          # Check that the value is accepted
          unless ACCEPTED_OPTIONS.key?(opt)
            raise Error, "Option class cannot accept parameter: #{opt}"
          end
          
          # Check that the value's class is accepted
          unless ACCEPTED_OPTIONS[opt].nil? || ACCEPTED_OPTIONS[opt].include?(value.class)
            raise Error, "Option parameter :description must be of class: [#{ACCEPTED_OPTIONS[opt].join(', ')}]"
          end
          
          # Check if both default_is_nil and default_is_proc are provided
          if options[:default_is_nil] && options[:default_is_proc]
            raise Error, "Option '#{name}' cannot set both :default_is_nil and :default_is_proc to true!"
          end
          
          # Check that a default value and default_is_nil are not both provided
          if options[:default_is_nil] && options[:default]
            raise Error, "Option '#{name}' cannot both set :default_is_nil and provided a default value!"
          end
          
          # Check if default_is_proc is set but default is not set to a Proc
          if options[:default_is_proc] && !options[:default].is_a?(Proc)
            raise Error, "Option '#{name}' indicates :default_is_proc, but its default value is not a Proc! Received class: #{options[:default].class}"
          end
          
          # Set the value
          self.instance_variable_set("@#{opt}", value)
          
          @default_is_nil = options[:default_is_nil]
          @default_is_proc = options[:default_is_proc]
          
        end
        
        # Fill in some holes
        @required = false if @required.nil?
        
        # turn the accepted classes into an array if it isn't just for ease of handling later.
        @accepted_classes = Array.new(1, @accepted_classes) if (!@accepted_classes.is_a?(Array) && !@accepted_classes.nil?) 
        @accepted_values = Array.new(1, @accepted_values) if (!@accepted_values.is_a?(Array) && !@accepted_values.nil?)
        @description = Array.new(1, @description) if (!@description.is_a?(Array) && !@description.nil?)
        @default_description = Array.new(1, @default_description) if (!@default_description.is_a?(Array) && !@default_description.nil?)
        
        #@accepted_values = options[:accepted_values]
        #@accepted_classes = options[:accepted_classes]
        #@accepted_checker = options[:accepted_checker]
        
        #@description = options[:description]
        #@doc_group = options[:doc_group]
        
        #@required = options[:required] || false
      end
      
      def required?
        @required
      end
      
      def requirement_met?
        if required.is_a?(Proc)
          required.call(self)
        elsif required
          has_been_set?
        else
          true
        end
      end
      
      def default_is_nil?
        @default_is_nil
      end
      
      # Handles printing either a single line or multiple lines as html from 
      def _lines_to_html(lines)
      end
      
      def to_html(options = {})
        html = []
        
  	    # Create a new panel header for the option name and panel body for the content
        html << "<div class='panel panel-default'>"
        html << "<div class='panel-heading'><h4>#{name}</h4></div>"
        html << "<div class='panel-body'>"
        
        html << '<ul class="list-group">'
        li = '<li class="list-group-item">' # beginning list item html
        cli = '</li>' # closing list item html
        
        # Print the description if it has one. If not, complain about it.
        html << li
        if description.nil? || description.empty? || (description.size == 1 && description[0].empty?)
          html << "<p><strong>No Description Available</strong></p>"
          Origen.log.warning "No description available for parameter #{name}"
        else
          html << "<p><strong>Description:</strong></p>"
          html = html + description.map { |line| "<p style=\"margin: 15px;\">#{line}</p>" }
          #if description.is_a?(Array)
          #  description.each do |line|
          #    html << "<p>#{line}</p>"
          #  end
          #else
          #  html << "<p>#{description}</p>"
          #end
        end
        html << cli
        
        # Print the default value and its class
        html << li
        if default == ""
          html << "<p><strong>Default:</strong> (Empty String) (<code>String</code>)</p>"
        elsif default.nil? && default_is_nil?
          html << "<p><strong>Default:</strong> <code>nil</code> (<code>NilClass</code>)</p>"
        elsif default.nil?
          html << "<p><strong>Default:</strong> No default value set! (<code>NilClass</code>)</p>"
        elsif default.is_a?(Proc) && default_is_proc
          html << "<p><strong>Default:</strong> <code>Proc</code> (<code>Proc</code>)</p>"
        elsif default.is_a?(Proc)
          html << "<p><strong>Default:</strong> <code>Custom Proc</code> This default by a custom Proc object. (<code>Proc</code>)</p>"
        else
          html << "<p><strong>Default:</strong> <code>#{default}</code> (<code>#{default.class}</code>)</p>"
        end
        
        unless default_description.nil?
        end
        html << cli
        
        # Print the accepted classes/values and whether or not an accepted process is present
        html << li
        if accepted_classes
          html << "<p><strong>Accepted Classes:</strong> #{accepted_classes.map { |c| '<code>' + c.to_s + '</code>' }.join(', ')}</p>"
        end
        
        if accepted_values
          html << "<p><strong>Accepted Values:</strong> #{accepted_values.map { |c| '<code>' + c.to_s + '</code>' }.join(', ')}</p>"
        end
        
        if accepted_checker
          html << "Accpted Checker: <p>Has as accepted checker block</p>"
        end
        html << cli
        
        html << '</ul>' # Close the list
        
        # Close the panel div, panel body, and list item
        html << '</div>' # End Panel Body
        html << '</div>' # End Panel Div
        
        html.join("\n")
      end
    end

  end
end
