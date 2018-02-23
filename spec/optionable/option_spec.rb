RSpec.shared_examples :optionable_option do
  # The brunt of the work as actually done by the Optionable::Option class and the module methods
  # just perform operations on a list of Optionable::Option instances.
  # Add a bunch of tests to make sure the Option class is working.
  describe 'Origen::Optionable::Option Class' do
    context 'with dummy Optionable::Option classes' do
      
      describe 'initialization and setup parameters' do
        it 'initializes an instance' do
          option = Origen::Optionable::Option.new(:test)
          expect(option).to be_a Origen::Optionable::Option
          expect(option.name).to eql :test
          expect(option.required?).to be false
        end
        
        it 'will set default values for option parameters' do
          option = Origen::Optionable::Option.new(:test, default: "hello option!")
          expect(option.current_value).to eql "hello option!"
        end
        
        it 'can accept a Proc to run as the default value (dynamic default values)' do
          option = Origen::Optionable::Option.new(:test_proc, default: Proc.new { |option| "#{option.name}_default!"})
          expect(option.current_value).to be_a(String)
          expect(option.current_value).to eql("test_proc_default!")
        end
        
        it 'has an option to indicate that the default is a Proc object, and should not be run, but set' do
          option = Origen::Optionable::Option.new(:test_proc, default: Proc.new { |name, optionable| "#{name}_default!"}, default_is_proc: true)
          expect(option.current_value).to be_a(Proc)
        end
        
        it 'knows if it is required' do
          option = Origen::Optionable::Option.new(:test, required: true)
          expect(option.name).to eql :test
          expect(option.required?).to be true
        end
        
        it 'knows if its requirement is met' do
          option = Origen::Optionable::Option.new(:test, required: true)
          expect(option.requirement_met?).to be false
          
          option.set('hi')
          expect(option.requirement_met?).to be true
          
          option = Origen::Optionable::Option.new(:test, required: false)
          expect(option.requirement_met?).to be true
        end
        
        it 'counts a default value as meeting the required set' do
          option = Origen::Optionable::Option.new(:test, required: true, default: 'hi')
          expect(option.requirement_met?).to be true
        end
        
        it 'counts nil as a set value if :default_is_nil is true' do
          option = Origen::Optionable::Option.new(:test, required: true, default_is_nil: true)
          expect(option.requirement_met?).to be true
          expect(option.value).to be nil
        end
        
        it 'can accepted a block as a dynamic requirement met value' do
          option = Origen::Optionable::Option.new(:test, required: Proc.new { |option| $optionable_global_var})
          
          $optionable_global_var = true
          expect(option.requirement_met?).to be true
          
          $optionable_global_var = false
          expect(option.requirement_met?).to be false
        end
        
        it 'will complain if an unrecognized parameter is given during initialization' do
          expect {
            option = Origen::Optionable::Option.new(:test, default: 'Error', unknown: 'Error')
          }.to raise_error Origen::Optionable::Error, "Option class cannot accept parameter: unknown"
        end
        
        it 'will complain if an unsupported class is given to a parameter during initialization' do
          expect {
            option = Origen::Optionable::Option.new(:test, default: 'Error', description: {})
          }.to raise_error Origen::Optionable::Error, "Option parameter :description must be of class: [String, Array]"
        end
        
        it 'complains if the default value does not meet the :accepted_classes criteria' do
          expect {
            Origen::Optionable::Option.new :test, default: "hello option!", accepted_values: [:hi], accepted_classes: [Symbol]
          }.to raise_error Origen::Optionable::UnacceptedClassError, /Error in option test when setting default value: Value's class 'String' is not accepted for option 'test'/
        end
        
        it 'complains if the default value does not meet the :accepted_values criteria' do
          expect {
            Origen::Optionable::Option.new :test, default: "hello option!", accepted_values: ["hello", "hi"]
          }.to raise_error Origen::Optionable::UnacceptedValueError, /Error in option test when setting default value: Value 'hello option!' is not accepted for option 'test'/
        end
        
        it 'complains if the default value does not meet the :accepted_checker criteria' do
          expect {
            Origen::Optionable::Option.new :test, default: "hello option!", accepted_values: ["hello", "hi"],
              accepted_checker: proc { |value| value != "hello option!" }
          }.to raise_error Origen::Optionable::AcceptedCheckerFailed, /Error in option test when setting default value: Value 'hello option!' failed to pass the given checker!/
        end
        
        it 'complains if the default Proc does not meet the :accepted_classes criteria' do
          expect {
          }.to raise_error Origen::Optionable::UnacceptedClassError, /Error in option test when setting default value from Proc object: Value's class 'String' is not accepted for option 'test'/
        end
        
        it 'complains if the default Proc does not meet the :accepted_values criteria' do
         expect {
         }.to raise_error Origen::Optionable::UnacceptedValueError, /Error in option test when setting default value from Proc object: Value 'hello option!' is not accepted for option 'test'/
        end
        
        it 'complains if the default Proc does not meet the :accepted_checker criteria' do
          expect {
          }.to raise_error Origen::Optionable::AcceptedCheckerFailed, /Error in option test when setting default value from Proc object: Value 'hello option!' failed to pass the given checker!/
        end
        
        it 'runs the checkers in the following order: accepted_classes, accepted_checker, accepted_values' do
          expect {
          }.to raise_error Origen::Optionable::UnacceptedClassError
          
          expect {
          }.to raise_error Origen::Optionable::AcceptedCheckerFailed
          
          expect {
          }.to raise_error Origen::Optionable::UnacceptedValueError
        end
        
        it 'complains if :default and :default_is_nil are both set' do
          expect {
            Origen::Optionable::Option.new :test, default: "hello option!", default_is_nil: true
          }.to raise_error Origen::Optionable::Error, /Option 'test' cannot both set :default_is_nil and provided a default value!/
        end
        
        it 'complains if both :default_is_nil and :default_is_proc are set' do
          expect {
            Origen::Optionable::Option.new :test, default_is_nil: true, default_is_proc: true
          }.to raise_error Origen::Optionable::Error, "Option 'test' cannot set both :default_is_nil and :default_is_proc to true!"
        end
        
        it 'complains if :default_is_proc is set and the default value is not a Proc' do
          expect {
            Origen::Optionable::Option.new :test, default: "hello option!", default_is_proc: true
          }.to raise_error Origen::Optionable::Error, "Option 'test' indicates :default_is_proc, but its default value is not a Proc! Received class: String"
        end
      end
      
      describe 'setting values' do
        it 'sets the current value' do
          option = Origen::Optionable::Option.new(:test)
          option.set "Hi"
          expect(option.current_value).to eql "Hi"
        end
        
        it 'complains if it does not meet the :accepted_classes criteria' do
          opt = Origen::Optionable::Option.new :test, accepted_values: [:hi], accepted_classes: [Symbol]
          expect {
            opt.set('hi')
          }.to raise_error Origen::Optionable::UnacceptedClassError, "Value's class 'String' is not accepted for option 'test'. Accepted classes are: [Symbol]"
          end
        
        it 'complains if it does not meet the :accepted_values criteria' do
          opt = Origen::Optionable::Option.new :test, accepted_values: [:hi], accepted_classes: [Symbol]
          expect {
            opt.set(:hello)
          }.to raise_error Origen::Optionable::UnacceptedValueError, "Value 'hello' is not accepted for option 'test'. Accepted values are: [:hi]"
        end
        
        it 'complains if it does not meet the :accepted_checker criteria' do
          opt = Origen::Optionable::Option.new :test, accepted_checker: proc { |value| value == "hello option!" }
          expect {
            opt.set('hello!')
          }.to raise_error Origen::Optionable::AcceptedCheckerFailed, "Value 'hello!' failed to pass the given checker!"
        end
        
        it 'will catch and rethrow an Origen::Optionable::AcceptedCheckerFailed with the default message' do
          opt = Origen::Optionable::Option.new :test, accepted_checker: proc { |value| 
            raise Origen::Optionable::AcceptedCheckerFailed if value != "hello option!"
            true 
          }
          expect {
            opt.set('hello!')
          }.to raise_error Origen::Optionable::AcceptedCheckerFailed, /Value 'hello!' failed to pass the given checker!/
        end
        
        it 'will catch and rethrow an Origen::Optionable::AcceptedCheckerFailed with the provided message' do
          opt = Origen::Optionable::Option.new :test, accepted_checker: proc { |value| 
            raise Origen::Optionable::AcceptedCheckerFailed, "Value #{value} was not set to 'hello option!'" if value != "hello option!"
            true 
          }
          expect {
            opt.set('hello!')
          }.to raise_error Origen::Optionable::AcceptedCheckerFailed, "Value hello! was not set to 'hello option!'"
        end
        
        it 'will catch any other exception in the :accepted_checker and rethrow it, stating that its in the checker' do
          opt = Origen::Optionable::Option.new :test, accepted_checker: proc { |value| value == value2 }
          expect {
            opt.set('hi')
          }.to raise_error NameError, /Error when running checker for option test: undefined local variable or method `value2'/
        end
        
        it 'complains if the provided accepted_checker does not return a true or false.' do
          opt = Origen::Optionable::Option.new :test, accepted_checker: proc { |value| "hi" }
          expect {
            opt.set('hi')
          }.to raise_error Origen::Optionable::Error, /:accepted_checker proc did not return a true or false value! Received value: hi Of class: String/
        end
      end
      
      describe 'retrieving values' do
        it 'will retrieve its current set value' do
          option = Origen::Optionable::Option.new(:test)
          option.set "Hello!"
          expect(option.value).to eql "Hello!"
        end
        
        it 'sets the :has_been_set value to true after the value has been set the first time' do
          option = Origen::Optionable::Option.new(:test)
          expect(option.has_been_set?).to be false
          
          option.set "Hello!"
          expect(option.value).to eql "Hello!"
          expect(option.has_been_set?).to be true
        end
        
        it 'will complain if a value is retrieved without a default value and without having been set' do
          option = Origen::Optionable::Option.new(:test)
          expect {
            option.value
          }.to raise_error Origen::Optionable::UnsetValueError, /Tried to retrieve the value for option 'test'/
        end
        
        it 'will set the default as nil and allow it to be retrieved if :default_is_nil is true' do
          option = Origen::Optionable::Option.new(:test, default_is_nil: true)
        end
                
      end
    end
  end

end
