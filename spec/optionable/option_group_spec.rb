RSpec.shared_examples :optionable_option_group do
  describe 'Option Groups' do

    it 'can instantiate an option group' do
      #handler = Origen::Optionable::OptionHandler.new # Basic handler object
      handler = OptionableSpec.new_optionable_instance
      option_group = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: handler)
    end
  
    context 'With dummy option handler' do
      before :context do
        @handler = OptionableSpec.new_optionable_instance # Basic handler object
        @option_group = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
      end
      
      it 'has a name' do
        #puts @option_group._name.red
        #puts @option_group
        expect(@option_group._name).to eql('Test')
        expect(@option_group.name).to eql('Test')
      end
      
      it 'has a handler' do
        expect(@option_group._handler).to be_a(Origen::Optionable::Optionable)
      end
      
      it 'can be initialized with a description' do
        opt_group = Origen::Optionable::OptionGroup.new(
          name: 'Test Init',
          description: 'Test Group',
          option_handler: @handler)
        
        expect(opt_group._name).to eql('Test Init')
        expect(opt_group._description).to eql('Test Group')
      end
      
      it 'complains if it is initialized without a name' do
        expect {
          Origen::Optionable::OptionGroup.new(option_handler: @handler)
        }.to raise_error Origen::Optionable::Error, 'A name must be provided to instantiate an option group!'
      end
      
      it 'complains if it is initialized without a handler' do
        expect {
          Origen::Optionable::OptionGroup.new(name: 'Test')
        }.to raise_error Origen::Optionable::Error, 'An Origen::Optionable::Optionable object must be given to instantiate an option group!'
      end
      
      it 'complains if the handler is not of class Origen::Optionable::Optionable' do
        expect {
          Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: 'Hi')
        }.to raise_error Origen::Optionable::Error, 'An OptionGroup\'s handler must be of class Origen::Optionable::Optionable!. Received class: String'
      end
    end
      
    context 'with dummy options' do
      before :context do
        @handler = OptionableSpec.new_optionable_instance
        
        # Make three dummy options
        @test_opt_1 = Origen::Optionable::Option.new(:test1)
        @test_opt_2 = Origen::Optionable::Option.new(:test2)
        @test_opt_3 = Origen::Optionable::Option.new(:test3)
        
        # Add a generic option group to use
        @opt_group = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
      end
      
      describe 'adding options' do
        it 'starts with no options defined' do
          expect(@opt_group._options).to be_empty
        end
        
        it 'can add a single option' do
          #opt_group = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
          @opt_group._add(:test1)
          
          expect(@opt_group._options).to eql([:test1])
        end
        
        it 'can add multiple options at once' do
          #opt_group = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
          #opt_group._add(:test1)
          @opt_group._add(:test2, :test3)
          
          expect(@opt_group._options).to eql([:test1, :test2, :test3])
        end
      end
      
      describe 'defining new groups' do
        it 'starts with no groups defined' do
          expect(@opt_group._groups).to be_empty
        end
        
        it 'can define a new group' do
          @opt_group._define_group(:new_grp)
          
          expect(@opt_group._groups.keys).to include(:new_grp)
        end
        
        it 'can access the new group with an accessor' do
          expect(@opt_group).to_not respond_to(:accessor_group)
          @opt_group._define_group(:accessor_group)
          expect(@opt_group).to respond_to(:accessor_group)
          expect(@opt_group.accessor_group).to be_a(Origen::Optionable::OptionGroup)
          expect(@opt_group._groups.keys).to include(:accessor_group)
        end
        
        it 'can define a new group with \'method missing\'' do
          expect(@opt_group).to_not respond_to(:method_missing_group)
          @opt_group.method_missing_group
          expect(@opt_group).to respond_to(:method_missing_group)
          expect(@opt_group.method_missing_group).to be_a(Origen::Optionable::OptionGroup)
          expect(@opt_group._groups.keys).to include(:method_missing_group)
        end
        
        it 'sets the parent of the new groups to the calling parent' do
          expect(@opt_group.method_missing_group._parent).to eql(@opt_group)
        end
        
        #it 'will define a new group if the accessor does not exists and its not a reserved method' do
        #  fail
        #end
        
        #it 'will add a new group if it is a reserved name, but will not override the method (i.e., it gets no accessor)' do
        #  fail
        #end
      end
      
      describe 'configuring an existing group' do
        #it 'can configure the parent' do
        #  expect(@opt_group._description).to be_nil
        #end
        
        it 'can configure the description' do
          expect(@opt_group._description).to be_nil
          @opt_group._config(description: 'Test Group Description')
          expect(@opt_group._description).to eql('Test Group Description')
        end
        
        it 'complains if an unknown config is given' do
          expect {
            @opt_group._config(unknown: 'Random')
          }.to raise_error Origen::Optionable::Error, /Unknown config option :unknown was given. Available config options are:/
        end
        
        #it 'can configure the name' do
        #  fail
        #end
      end
    end
        
    context 'with dummy options' do
      before :context do
        @handler = OptionableSpec.new_optionable_instance
        
        # Make three dummy options
        @test_opt_1 = Origen::Optionable::Option.new(:test1)
        @test_opt_2 = Origen::Optionable::Option.new(:test2)
        @test_opt_3 = Origen::Optionable::Option.new(:test3)
        
        # Add a generic option group to use for these tests
        @opt_group = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
        @opt_group._add(:test1, :test2, :test3)
        @opt_group._define_group(:test_grp1)
        @opt_group._define_group(:test_grp2)
      end
      
      describe 'option and group ordering' do
        it 'has a default order of :groups_first' do
          expect(@opt_group._order).to eql(:groups_first)
        end
        
        it 'generates the current order' do
          expect(@opt_group._generate_order).to eql([:test_grp1, :test_grp2, :test1, :test2, :test3])
        end
        
        it 'can change the order to :options_first' do
          @opt_group._order = :options_first
          expect(@opt_group._order).to eql(:options_first)
          expect(@opt_group._generate_order).to eql([:test1, :test2, :test3, :test_grp1, :test_grp2])
        end
        
        it 'will accept an array of known options/groups' do
          order = [:test_grp1, :test1, :test_grp2, :test2, :test3]
          @opt_group._order = order
          expect(@opt_group._order).to eql(order)
          expect(@opt_group._generate_order).to eql(order)
        end
        
        it 'can accept options/group instances as well in the array' do
          order = [:test_grp1, :test1, @opt_group.test_grp2, @test_opt_2, :test3]
          @opt_group._order = order
          expect(@opt_group._order).to eql(order)
          expect(@opt_group._generate_order).to eql([:test_grp1, :test1, :test_grp2, :test2, :test3])
        end
        
        it 'complains if an array is given a name that does not correspond to a known option or group' do
          expect {
            @opt_group._order = [:test_grp1, :test1, :test_grp2, :test2, :test3, :unknown]
          }.to raise_error Origen::Optionable::UnknownOptionError, "Problem setting order in OptionGroup 'Test': Unknown option or group 'unknown'"
        end
        
        it 'complains if an option instance does not correspond to a known option' do
          opt = Origen::Optionable::Option.new(:random)
          expect {
            @opt_group._order = [:test_grp1, :test1, :test_grp2, :test2, :test3, opt]
          }.to raise_error Origen::Optionable::UnknownOptionError, "Problem setting order in OptionGroup 'Test': Unknown option instance 'random'"
        end
        
        it 'complains if a group instance does not correspond to a known group' do
          grp = Origen::Optionable::OptionGroup.new(name: 'random grp', option_handler: @handler)
          expect {
            @opt_group._order = [:test_grp1, :test1, :test_grp2, :test2, :test3, grp]
          }.to raise_error Origen::Optionable::UnknownOptionError, "Problem setting order in OptionGroup 'Test': Unknown group instance 'random grp'"
        end
        
        it 'complains if the order is not :groups_first, :options_first, or an array' do
          expect {
            @opt_group._order = :unknown
          }.to raise_error Origen::Optionable::Error, "Unknown order 'unknown'! Available values are :groups_first, :options_first or an Array containing a custom order"
        end
=begin        
        it 'will show the option first if both an option and group share the same name' do
          fail
        end
=end
      end
    end
    
    context 'with dummy options' do
      before :context do
        # Create three option groups for options first, groups first, and a customized order.
        # Each will have the same input.
        # Run the same tests for each and make sure each changes accordingly.
        
        @handler = OptionableSpec.new_optionable_instance
        
        # Make three dummy options
        @options_first_opt1 = Origen::Optionable::Option.new(:test1)
        @options_first_opt2 = Origen::Optionable::Option.new(:test2)
        @options_first_opt3 = Origen::Optionable::Option.new(:test3)
        
        @groups_first = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
        @groups_first._add(:test1, :test2, :test3)
        @groups_first._define_group(:test_grp1)
        @groups_first._define_group(:test_grp2)
        
        @options_first = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
        @options_first._add(:test1, :test2, :test3)
        @options_first._define_group(:test_grp1)
        @options_first._define_group(:test_grp2)
        
        @customized = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
        @customized._add(:test1, :test2, :test3)
        @customized._define_group(:test_grp1)
        @customized._define_group(:test_grp2)
      end
      
      describe 'shuffling options and groups around' do
        
        it 'has methods :_shift_option_up aliased to method :_shift_options_up' do
          expect(@groups_first.method(:_shift_option_up)).to eql(@groups_first.method(:_shift_options_up))
        end
        
        it 'has methods :_shift_option_down aliased to method :_shift_options_down' do
          expect(@groups_first.method(:_shift_option_down)).to eql(@groups_first.method(:_shift_options_down))
        end
=begin        
        it 'can shift an option up (towards the front)' do
          @options_first._shift_option_up
          @groups_first._shift_option_up
          @customized._shift_option_up
          fail
        end
        
        it 'can shift an option down (towards the back)' do
          fail
        end
        
        it 'can shift a group up (towards the front)' do
          fail
        end
        
        it 'can shift a group down (towards the back)' do
          fail
        end
=end

      end
    end
    
    context 'with dummy options' do
      before :context do
        @handler = OptionableSpec.new_optionable_instance
        @opt_group = Origen::Optionable::OptionGroup.new(name: 'Test', option_handler: @handler)
      end
      
      describe 'other settings/methods' do
        it 'starts collapsed by default' do
          expect(@opt_group._start_collapsed?).to be true
          expect(@opt_group._start_expanded?).to be false
        end
        
        it 'can be configured to start expanded' do
          @opt_group._config(start_expanded: true)
          expect(@opt_group._start_collapsed?).to be false
          expect(@opt_group._start_expanded?).to be true
        end
        
        it 'complains if the config variable :start_expanded is set to something other than true or false' do
          expect {
            @opt_group._config(start_expanded: :unknown)
          }.to raise_error Origen::Optionable::Error, 'Config variable :start_expanded for OptionGroup Test must be either true or false! Received: unknown'
        end
      end    
    end
    
  end
end
