module OptionableSpec
  class OptionableTest
    include Origen::Optionable
    include Origen::Model
  end
end

describe 'Optionable Spec' do
  #context 'with dummy Optionable model' do
  
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
          
          it 'knows if it is required' do
            option = Origen::Optionable::Option.new(:test, required: true)
            expect(option.name).to eql :test
            expect(option.required?).to be true
          end
          
          it 'will complain if an unrecognized parameter is given during initialization' do
            expect {
              option = Origen::Optionable::Option.new(:test, default: 'Error', unknown: 'Error')
            }.to raise_error OptionableError, "Option class cannot accept parameter 'unknown'."
          end
          
          it 'will complain if an unsupported class is given to a parameter during initialization' do
            expect {
              option = Origen::Optionable::Option.new(:test, default: 'Error', description: {})
            }.to raise_error OptionableError, "Option parameter :description must be of class: [String, Array]"
          end
          
          it 'complains if the default value does not meet the :accepted_classes criteria' do
            expect {
              Origen::Optionable::Option.new :test, default: "hello option!", accepted_values: [:hi], accepted_classes: [Symbol]
            }.to raise_error Origen::Optionable::UnacceptedClassError, /Default value's class 'String' is not accepted for option 'test'/
          end
          
          it 'complains if the default value does not meet the :accepted_values criteria' do
            expect {
              Origen::Optionable::Option.new :test, default: "hello option!", accepted_values: ["hello", "hi"]
            }.to raise_error Origen::Optionable::UnacceptedValueError, /Default value 'hello option!' is not accepted for option 'test'/
          end
          
          it 'complains if the default value does not meet the :accepted_checker criteria' do
            expect {
              Origen::Optionable::Option.new :test, default: "hello option!", accepted_values: ["hello", "hi"],
                accepted_checker: proc { |value| value != "hello option!" }
            }.to raise_error Origen::Optionable::AcceptedCheckerFailed, /Default value 'hello option!' failed to pass the given checker!/
          end
          
          it 'complains if :default and :default_is_nil are both set' do
            expect {
              Origen::Optionable::Option.new :test, default: "hello option!", accepted_values: [:hi], accepted_classes: [Symbol]
            }.to raise_error Origen::Optionable::UnacceptedClassError, /Value's class 'String' is not accepted for option 'test'/
           end
        end
        
        describe 'setting values' do
          it 'sets the current value' do
            option = Origen::Optionable::Option.new(:test)
            option.set "Hi"
            expect(option.current_value).to eql "Hi"
          end
          
          it 'complains if it does not meet the :accepted_classes criteria' do
            expect {
              Origen::Optionable::Option.new :test, accepted_values: [:hi], accepted_classes: [Symbol]
            }.to raise_error Origen::Optionable::UnacceptedClassError, /Value's class 'String' is not accepted for option 'test'/
           end
          
          it 'complains if it does not meet the :accepted_values criteria' do
            expect {
              Origen::Optionable::Option.new :test, accepted_values: ["hello", "hi"]
            }.to raise_error Origen::Optionable::UnacceptedValueError, /Value 'hello option!' is not accepted for option 'test'/
          end
          
          it 'complains if it does not meet the :accepted_checker criteria' do
            expect {
              Origen::Optionable::Option.new :test, accepted_values: ["hello", "hi"],
                accepted_checker: proc { |value| value != "hello option!" }
            }.to raise_error Origen::Optionable::AcceptedCheckerFailed, /Value 'hello option!' failed to pass the given checker!/
          end
          
          it 'can complain with a custom message if it does not meet the :accepted_checker criteria' do
            expect {
              Origen::Optionable::Option.new :test,
                accepted_checker: proc { |value| raise Origen::Optionable::AcceptedCheckerFailed, "#{value} was not set to 'hello option!'" if value != "hello option!"; true }
            }.to raise_error Origen::Optionable::AcceptedCheckerFailed, /Value 'hello option!' failed to pass the given checker!/
          end
          
          it 'will catch an error in the :accepted_checker and rethrow that error' do
            expect {
              Origen::Optionable::Option.new :test,
                accepted_checker: proc { |value| value == value2 }
            }.to raise_error Origen::Optionable::Error, /:accepted_checker proc encountered exception 'NoMethodError' with message 'no method value2'/
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
          
          it 'will complain if :default is given and default_is_nil is set' do
            expect {
              option = Origen::Optionable::Option.new(:test, default_is_nil: true, default: :not_nil)
            }.to raise_error Origen::Optionable::Error, "Option 'test' cannot have both :default and :default_is_nil set simultaneously!"
          end
          
        end
      end
    end
    
    describe 'Origen::Optionable::OptionHandler' do
      context 'With Dummy OptionHandler' do
        before :context do
          @option_handler = Origen::Optionable::OptionHandler.new
        end
        
        it 'Can be initiailized' do
          expect(@option_handler).to be_a(Origen::Optionable::OptionHandler)
        end
        
        describe 'registering/adding options' do
          it 'can add options (single option pair)' do
            @option_handler.add(:test1, {default: "test1", description: "test option 1"})
            expect(@option_handler._options).to have_key(:test1)
          end
          
          it 'can add options (multiple option pairs)' do
            @option_handler.add(:test2, {default: "test2", description: "test option 2"},
                                :test3, {default: "test3", description: "test option 3"})
            expect(@option_handler._options).to have_key(:test2)
            expect(@option_handler._options).to have_key(:test3)
          end
          
          it 'can add options (single Optionable::Option class)' do
            option = Origen::Optionable::Option.new(:test4, default: "test4", description: "test 4")
            @option_handler.add(option)
            expect(@option_handler._options).to have_key(:test4)
          end
          
          it 'can add options (multiple Optionable::Option classes)' do
            option1 = Origen::Optionable::Option.new(:test5, default: "test5", description: "test 5")
            option2 = Origen::Optionable::Option.new(:test6, default: "test6", description: "test 6")
            @option_handler.add(option1, option2)
            expect(@option_handler._options).to have_key(:test5)
            expect(@option_handler._options).to have_key(:test6)
          end
          
          it 'can add options (mix of Optionable::Option classes and option pairs)' do
            option1 = Origen::Optionable::Option.new(:test7, default: "test7", description: "test 7")
            option2 = Origen::Optionable::Option.new(:test9, default: "test9", description: "test 9")
            @option_handler.add(option1, :test8, {default: "test8", description: "test 8"},
                                option2, :test10, {default: "test10", description: "test 10"})
            expect(@option_handler._options).to have_key(:test8)
            expect(@option_handler._options).to have_key(:test9)
            expect(@option_handler._options).to have_key(:test10)
          end
          
          it 'can add an option using []= notation (Symbol, Hash)' do
            @option_handler[:test11] = {default: "test11", description: "test 11"}
            expect(@option_handler._options).to have_key(:test11)
          end
          
          it 'can add an option using []= notation (Symbol, Option)' do
            option = Origen::Optionable::Option.new(:test12, default: "test11", description: "test 11")
            @option_handler[:test12] = option
            expect(@option_handler._options).to have_key(:test12)
          end
          
          it 'complains if an option does not come in a pair (single pair)' do
            expect {
              @option_handler.add(:test_fail, :test_fail)
            }.to raise_error Origen::Optionable::Error, /Input was not formatted as an option pair as name (Symbol), parameters (Hash). Found pair :test_fail, :test_fail/
          end
          
          it 'complains if an option does not come in a pair (multiple pairs)' do
            option = Origen::Optionable::Option(:dummy)
            expect {
              @option_handler.add(:test_a, {default: "test_a", description: "test A"}, :test_b, option)
            }.to raise_error Origen::Optionable::Error, /Input was not formatted as an option pair as name (Symbol), parameters (Hash). Found pair :test_fail, :test_fail/
          end
          
          it 'complains if an option has already been added (single pair)' do
            expect {
              @option_handler.add(:test1, {})
            }.to raise_error Origen::Optionable::NameInUseError, /Option :test1 has already been registered!/
          end
          
          it 'complains if an option has already been added (Option class)' do
            option = Origen::Optionable::Option.new(:test1)
            expect {
              @option_handler.add(option)
            }.to raise_error Origen::Optionable::NameInUseError, /Option :test1 has already been registered!/
          end
          
          it 'complains when adding using []= notation but the name doesn\'t equal the object.name' do
            option = Origen::Optionable::Option.new(:test_a)
            expect {
              @option_handler[:test_b] = option
            }.to raise_error Origen::Optionable::Error, /Given name :test_b doesn't match option name :test_a/
          end
        end
        
        describe 'Setting options' do
          it 'can set individual options (single option pair)' do
            @option_handler.set(:test1, "Test 1B")
            expect(@option_handler._options[:test1].value).to eql("Test 1B")
          end
          
          it 'can set individual options (multiple option pairs)' do
            @option_handler.set(:test2, "Test 2B", :test3, "Test 3B")
            expect(@option_handler._options[:test2].value).to eql("Test 2B")
            expect(@option_handler._options[:test3].value).to eql("Test 3B")
          end
          
          it 'can set individual options using []= notation' do
            @option_handler[:test4] = "Test 4B"
            expect(@option_handler._options[:test4].value).to eql("Test 4B")
          end
          
          it 'complains when trying to set an option that does not exist (single option)' do
            expect {
              @option_handler.set(:test_unknown, "Value")
            }.to raise_error Origen::Optionable::UnknownOptionError, /Option :test_unknown is not a registered option!/
          end
          
          it 'complains when trying to set an option that does not exist (multiple options)' do
            expect {
              @option_handler.set(:test10, "Test 10B", :test_unknown, "Value")
            }.to raise_error Origen::Optionable::UnknownOptionError, /Option :test_unknown is not a registered option!/
          end
          
          it 'complains when trying to set an option that does not exist ([] notation)' do
            expect {
              @option_handler[:test_unknown] = "Value"
            }.to raise_error Origen::Optionable::UnknownOptionError, /Option :test_unknown is not a registered option!/
          end
          
          it 'complains if names and values are not in pairs' do
            expect {
              @option_handler.set(:test8)
            }.to raise_error Origen::Optionable::Error, /Option :test8 did not come as a name\/ value pair!/
          end
          
          #it 'does not complain about extra options with (!) is not used' do
          #  fail
          #end
          
          #it 'complains about extra options when (!) is used' do
          #  fail
          #end
          
          #it 'complains if options marked as required are not required' do
          #  fail
          #end
        end
        
        describe 'Merging Options' do
          it 'can merge options with a given hash' do
            @option_handler.merge(test5: "Test 5B", test6: "Test 6B", test7: "Test 7B")
            expect(@option_handler._options[:test5]).to eql("Test 5B")
            expect(@option_handler._options[:test6]).to eql("Test 6B")
            expect(@option_handler._options[:test7]).to eql("Test 7B")
          end
        
          it 'complains when trying to set an option that does not exist (merge), OPTIONABLE_ON_EXTRA_OPTIONS not set' do
            expect {
              @option_handler.merge(test_10: "Test 10C", test_unknown: "Value")
            }.to raise_error UnknownOptionError, /Option :test_unknown is not a registered option!/
          end
          
          it 'warns about extra options OPTIONABLE_ON_EXTRA_OPTIONS = :warn' do
            @option_handler_warn.merge(test_warn: "Test Warn", test_unknown_warn: "Value")
            expect(Origen.log.msg_hash[:warn][nil][-1]).to include('Option :test_unknown_warn is not a registered option!')
            expect(@option_handler_warn._options[:test]).to eql "Test Warn"
            expect(@option_handler_warn._options).to_not have_key(:test_unknown_warn)
          end
          
          it 'ignore extra options if OPTIONABLE_ON_EXTRA_OPTIONS = :ignore' do
            @option_handler_ignore.merge(test_ignore: "Test Ignore", test_unknown_ignore: "Value")
            expect(Origen.log.msg_hash[:info][nil][-1]).to_not include('Option :test_unknown_ignore is not a registered option!')
            expect(Origen.log.msg_hash[:warn][nil][-1]).to_not include('Option :test_unknown_ignore is not a registered option!')
            expect(Origen.log.msg_hash[:error][nil][-1]).to_not include('Option :test_unknown_ignore is not a registered option!')
            expect(@option_handler_warn._options[:test_ignore]).to eql "Test Ignore"
            expect(@option_handler_warn._options).to_not have_key(:test_unknown_ignore)
          end
          
          it 'complains about extra options if OPTIONABLE_ON_EXTRA_OPTIONS = :error' do
            # This is the same as the default case
            expect {
              @option_handler_error.merge(test_error: "Test Error", test_unknown: "Value")
            }.to raise_error Origen::Optionable::UnknownOptionError, /Option :test_unknown is not a registered option!/
          end
        end
        
        describe 'listing and retrieving option values and classes' do
          it 'can retrieve an option\'s value (single option)' do
            expect(@option_handler.value(:test1)).to eql("Test 1")
          end
          
          it 'can retrieve an option\'s value (multiple options)' do
            expect(@option_handler.value(:test1, :test2, :test3)).to eql(["Test 1", "Test 2", "Test 3"])
          end
          
          it 'can retrieve an option\'s value using [] notation' do
            expect(@option_handler[:test1]).to eql("Test 1")
          end
          
          it 'can retrieve and option\'s instance (single instance)' do
            opt = @option_handler.retrieve(:test1)
            expect(opt).to be_a(Origen::Optionable::Option)
            expect(opt.name).to eql(:test1)
          end
          
          it 'can retrieve and option\'s instance (multiple instances)' do
            opts = @option_handler.retrieve(:test2, :test3)
            expect(opts[0]).to be_a(Origen::Optionable::Option)
            expect(opts[1]).to be_a(Origen::Optionable::Option)
            expect(opts[0].name).to eql(:test2)
            expect(opts[1].name).to eql(:test3)
          end
          
          it 'complains when retrieving an options value but the option is not found' do
            expect {
              @option_handler.value(:test_unknown)
            }.to raise_error Origen::Optionable::UnknownOptionError, /Option :test_unknown is not a registered option!/
          end
          
          it 'complains when trying to retrieve an option that is not found' do
            expect {
              @option_handler.retrieve(:test_unknown)
            }.to raise_error Origen::Optionable::UnknownOptionError, /Option :test_unknown is not a registered option!/
          end
          
          it 'can list all currently registered options' do
            expect(@option_handler.list).to eql [:test1, :test2, :test3, :test4, :test5, :test6, :test7, :test8, :test9, :test10, :test11, :test12]
          end
        end
        
        describe 'removing options' do
          it 'can remove options (single option)' do
            @option_handler.remove(:test1)
            expect(@option_handler._options).to_not have_key(:test1)
          end
          
          it 'can remove options (multiple option)' do
            @option_handler.remove(:test2, :test3)
            expect(@option_handler._options).to_not have_key(:test2)
            expect(@option_handler._options).to_not have_key(:test3)
          end
          
          it 'complains if the options to remove are not present' do
            expect {
              @option_handler.remove(:test1)
            }.to raise_error Origen::Optionable::UnknownOptionError, /Option :test1 is not a registered option!/
          end
        end
      end
    end
    
    describe 'Origen::Optionable Module' do
      context 'with dummy Optionable includer' do
        before :context do
          @optionable_test = OptionableSpec::OptionableTest.new
        end
      
        [:add_option, :set_option, :remove_option, :list_options, :generate_options_html].each do |method|
          it "adds the Optionable API: #{method}" do
            expect(@optionable_test).to respond_to(method)
          end
        end
        
        it 'initializes an Optionable::Option class automatically' do
          expect(@optionable_test._optionable_handler).to be_a(Origen::Optionable::OptionHandler)
        end
      
      #it '' do
      #  fail
      #end
      end
    end
    
  #end
end
