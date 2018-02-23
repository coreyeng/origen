module OptionableSpec
  class OptionableTest
    include Origen::Optionable
    include Origen::Model
  end
  
  def self.new_optionable_class
    OptionableTest.new
  end
  
  def self.new_optionable_instance
    Origen::Optionable::Optionable.new
  end
end

fdescribe 'Optionable Spec' do
  #require File.join(File.expand_path(File.dirname('__FILE__')), 'spec/optionable/option.rb')
  #context 'with dummy Optionable model' do
  
  # Run these example groups in under the 'Optionable Spec' header and in the order I want.
  include_examples :optionable_option
  #include_examples :optionable_option_handler
  include_examples :optionable_option_group
=begin    
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
    end
=end    
  # This is just checking that the Componentable/Optionable interaction is working.
  # The actual testing of Optionable::Option and Optionable::Group are in the optionable/ directory.
  describe 'accessing the underlying :optionable class' do
    [:add_option, :set_option, :remove_option, :list_options, :generate_options_html].each do |method|
      it "adds the Optionable API: #{method}" do
        expect(@optionable_test).to respond_to(method)
      end
    end

    context 'with dummy Optionable includer' do
      it 'can access the optionable class' do
        o = OptionableSpec.new_optionable_class
        expect(o.optionable).to be_a(Origen::Optionable::Optionable)
      end
    end
  end
  
  describe 'Adding options' do
    context 'with dummy Optionable includer' do
      before :context do
        @optionable_test = OptionableSpec.new_optionable_class
      end
      
      it 'can add an option' do
        o = @optionable_test.add_optionable(:test_opt)
        expect(o).to be_a(Origen::Optionable::Option)
        expect(@optionable_test.optionable._componentable_container).to have_key(:test_opt) 
      end
      
      it 'complains if an option to add is already present' do
        expect {
          @optionable_test.add_optionable(:test_opt)
        }.to raise_error Origen::Optionable::NameInUseError, 'Optionable has already registered an option :test_opt'
      end
      
      it 'complains if the user tries to supply an :instances parameter to the option' do
        expect {
          @optionable_test.add_optionable(:test_instances, instances: 2)
        }.to raise_error Origen::Optionable::Error, 'Optionable does not allow multiple instances of an option!'
      end
      
      it 'complains if the user tries to supply a :class_name parameter to the option' do
        expect {
          @optionable_test.add_optionable(:test_class_name, class_name: Origen::Optionable::Option)
        }.to raise_error Origen::Optionable::Error, 'Optionable does not allow a :class_name to be specified. Optionable forces all added objects to be of class Origen::Optionable::Option'
      end
    end
  end
    
  describe 'Checking Required Options' do
  end
    
    describe 'Setting Options' do
      context 'with dummy Optionable includer' do
        before(:context) do
          @optionable_test = OptionableSpec.new_optionable_class
          @optionable_test.add_optionable(:set_test, default: 'hi')
        end
        
        it 'can set an option' do
          expect(@optionable_test.optionable[:set_test].value).to eql('hi')
          @optionable_test.set_optionable(:set_test, 'value')
          expect(@optionable_test.optionable[:set_test].value).to eql('value')
        end
        
        it 'complains if an unknown option is set' do
          expect {
            @optionable_test.set_optionable(:unknown, 'value')
          }.to raise_error Origen::Optionable::UnknownOptionError, "Option :unknown is not a registered option!"
        end
      end
        
      context 'with dummy Optionable includer' do
        before(:context) do
          @optionable_test = OptionableSpec.new_optionable_class
          @optionable_test.add_optionable(:merge_test_1, default: 'hi')
          @optionable_test.add_optionable(:merge_test_2, default: 'hi')
          @optionable_test.add_optionable(:merge_test_3, default: 'hi')
        end
        
        it "can merge options from an 'option' hash" do
          expect(@optionable_test.optionable[:merge_test_1].value).to eql('hi')
          expect(@optionable_test.optionable[:merge_test_2].value).to eql('hi')
          expect(@optionable_test.optionable[:merge_test_3].value).to eql('hi')
          
          @optionable_test.merge_optionable({merge_test_1: 'test 1', merge_test_2: 'test 2'})
          
          expect(@optionable_test.optionable[:merge_test_1].value).to eql('test 1')
          expect(@optionable_test.optionable[:merge_test_2].value).to eql('test 2')
          expect(@optionable_test.optionable[:merge_test_3].value).to eql('hi')
        end
        
        it 'can print the merge ordering of the options' do
          expect(@optionable_test.optionable_merge_ordering).to eql(['merge_test_1', 'merge_test_2', 'merge_test_3'])
        end
        
        it 'complains if extra options are given (i.e., options are not found, but reports all)' do
          expect {
            @optionable_test.merge_optionable({merge_test_4: 'test 4', merge_test_5: 'test 5'})
          }.to raise_error Origen::Optionable::UnknownOptionError, "Option(s) :merge_test_4, :merge_test_5 were given but are not registered options."
        end
        
        it 'will merge options even if :fail_on_extra_options is set to false' do
          expect(@optionable_test.optionable[:merge_test_1].value).to_not eql('extra test 1')
          expect(@optionable_test.optionable[:merge_test_2].value).to_not eql('extra test 2')
          expect(@optionable_test.optionable[:merge_test_3].value).to_not eql('extra test 3')
          
          @optionable_test.merge_optionable({
            merge_test_1: 'extra test 1',
            merge_test_2: 'extra test 2',
            merge_test_3: 'extra test 3',
            merge_test_4: 'extra test 4',
            merge_test_5: 'extra test 5'
          }, fail_on_extra_options: false)

          expect(@optionable_test.optionable[:merge_test_1].value).to eql('extra test 1')
          expect(@optionable_test.optionable[:merge_test_2].value).to eql('extra test 2')
          expect(@optionable_test.optionable[:merge_test_3].value).to eql('extra test 3')
        end
      end
      
      context 'with dummy Optionable includer' do
        before(:context) do
          @optionable_test = OptionableSpec.new_optionable_class
          @optionable_test.add_optionable(:merge_test_1, default: 'hi')
          @optionable_test.add_optionable(:merge_test_2, default: 'hi')
          @optionable_test.add_optionable(:required_test_1, required: true)
          @optionable_test.add_optionable(:required_test_2, required: true)
        end
      
        it 'complains if not all required options are set' do
          expect {
            @optionable_test.merge_optionable({merge_test_1: 'test 1', merge_test_2: 'test 2'})
          }.to raise_error Origen::Optionable::Error, "Not all requirements met! Missing options :required_test_1, :required_test_2"
        end
        
        it 'will merge options even if requirements are not met if :requirements_check is set to false' do
          expect(@optionable_test.optionable[:merge_test_1].value).to_not eql('test 1')
          expect(@optionable_test.optionable[:merge_test_2].value).to_not eql('test 2')
          
          @optionable_test.merge_optionable({
            merge_test_1: 'test 1',
            merge_test_2: 'test 2',
          }, requirements_check: false)

          expect(@optionable_test.optionable[:merge_test_1].value).to eql('test 1')
          expect(@optionable_test.optionable[:merge_test_2].value).to eql('test 2')
        end
      end
    end
    
    describe 'Retreiving Options and Values' do
      context 'with dummy Optionable includer' do
        before(:context) do
          @optionable_test = OptionableSpec.new_optionable_class
        end
      end
      it 'fails' do
        fail
      end
    end
    
  describe 'Brief Componentable Check' do
    # All these methods should be added by Componentable. So, don't need to do any real testing of these.
    # More or less just make sure they're there.
    
    context 'with dummy Optionable includer' do
      before(:context) do
        @optionable_test = OptionableSpec.new_optionable_class
        @optionable_test.add_optionable(:hi_1, default: 'hi 1')
        @optionable_test.add_optionable(:hi_2, default: 'hi 2')
        @optionable_test.add_optionable(:hi_3, default: 'hi 3')
        @optionable_test.add_optionable(:hi_4, default: 'hi 4')
      end
      
      it 'can list available options' do
        expect(@optionable_test.list_optionables).to eql(['hi_1', 'hi_2', 'hi_3', 'hi_4'])
      end
      
      it 'can query if an option exists' do
        expect(@optionable_test.has_optionable?(:hi_1)).to be true
        expect(@optionable_test.has_optionable?(:unknown)).to be false
      end
      
      it 'can remove an existing option' do
        expect(@optionable_test.remove_optionable(:hi_1)).to be_a(Origen::Optionable::Option)
        expect(@optionable_test.list_optionables).to eql(['hi_2', 'hi_3', 'hi_4'])
      end
    end
  end  
end
