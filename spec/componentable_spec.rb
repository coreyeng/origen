require "spec_helper"

# Using some pretty generic names, so just to make sure it won't conflict with other classes.
module ComponentableSpec

  module TestComponent
    class TestComponent
      include Origen::Model
      include Origen::Componentable
      
      def initialize
      end
    end
  end
  
  module TestComponentWithoutModel
    class TestComponent
      include Origen::Componentable
    end
  end

  # Module containing all the test for 
  module NameTests
    class Tool; end
    class ToolSet; end
    class Toolset; end
    class High; end
    class Bus; end
    class Stress; end
    class Mesh; end
    class Bench; end
    class Analysis; end
    class Criterion; end
    class Box; end
    class Buzz; end
    
    class ToolCustomName
      COMPONENTABLE_PLURAL_NAME = 'Toolset'
    end
  end
  
  module InitTests
  	class IncluderTestManual
   	  include Origen::Componentable
    end
    
    class IncluderTestModel
      include Origen::Model
      include Origen::Componentable
    end
    
    module ToIncludeWithModel
      class ToIncludeWithModel
        include Origen::Model
        include Origen::Componentable
      end
    end
    
    module ToIncludeWithoutModel
      class ToIncludeWithoutModel
        include Origen::Componentable
      end
    end
    
    class ParentNoModel
      include ToIncludeWithModel
      
      def initialize
      end
    end
    
    class ParentNoModelInit
      include ToIncludeWithModel
      
      def initialize
        ToIncludeWithModel::ToIncludeWithModel.new
        Origen::Componentable.init_parent_class(self, ToIncludeWithModel::ToIncludeWithModel)
      end
    end
    
    class Init_Parent_With_Model_Component_Without
      include Origen::Model
      include TestComponentWithoutModel
    end
    
    class Init_Parent_And_Component_With_Model
      include Origen::Model
      include TestComponent
    end
  end
  
  #class TopEmpty
  #  include Origen::Model
  #  
  #  def initialize
  #  end
  #end

  #class TopPopulated
  #  include Origen::Model
  #  
  #  def initialize
  #  end
  #end
  
  class AddTest
    attr_reader :opts
    
    def initialize(options = {})
      @opts = options
    end
  end
  
  module ComponentableParentInitTest
    class InitWithModel
      include Origen::Model
      include TestComponent
    end
    
    #class InitWithoutModel
    #end
    
    #class Init_Parent_With_Model_Component_Without
    #  include Origen::Model
    #  include ComponentableSpec::TestComponentWithoutModel
    #end
  end
end

fdescribe 'Componentable' do
  context 'With dummy classes' do
    describe 'Componentable\'s class methods' do
    
      # Componetable.componentable_container_name summary:
      #  gets the name of the componentable container name at runtime
      describe 'Method: Componentable.componentable_container_name' do
        it 'Pluralizes the name (Tool)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Tool.new)[:plural].should == :tools
        end

        it 'Pluralizes the name (ToolSet)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::ToolSet.new)[:plural].should == :tool_sets
        end

        it 'Pluralizes the name (Toolset)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Toolset.new)[:plural].should == :toolsets
        end

        it 'Pluralizes the name -h (High)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::High.new)[:plural].should == :highs
        end
        
        it 'Pluralizes irregular case -s (Bus)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Bus.new)[:plural].should == :buses
        end

        it 'Pluralizes irregular case -ss (Stree)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Stress.new)[:plural].should == :stresses
        end

        it 'Pluralizes irregular case -sh (Mesh)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Mesh.new)[:plural].should == :meshes
        end

        it 'Pluralizes irregular case -ch (bench)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Bench.new)[:plural].should == :benches
        end
        
        it 'Pluralizes irregular case -is (Analysis)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Analysis.new)[:plural].should == :analyses
        end
        
        it 'Pluralizes the irregular case -on (Criterion)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Criterion.new)[:plural].should == :criteria
        end

        it 'Pluralizes irregular case -x (Box)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Box.new)[:plural].should == :boxes
        end
        
        it 'Pluralizes irregular case -z (Buzz)' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::Buzz.new)[:plural].should == :buzzes
        end
        
        it 'Uses the includer class\'s ComponentableName class variable instead if it is set' do
          Origen::Componentable.componentable_names(ComponentableSpec::NameTests::ToolCustomName.new)[:plural].should == :toolset
        end
      end
      
      # Componentable.init_includer_class summary:
      #  initializes the componentable objects/methods on the includer. Ex:
      #  class includer
      #    include Compomentable
      #    def initialize
      #      #=> includer.includers #=> no method exception
      #      #=> includer.respond_to?(:add) #=> false
      #
      #      Origen::Componentable.init_includer_class(self) #=> this is auto-called if Origen::Model is included
      #      #=> includer.includers #=> {}
      #      #=> includer.respond_to?(:add) #=> true
      #  ...
      describe 'Method: Componentable.init_includer_class' do
        it 'initially does not have a componentable_container' do
        	i = ComponentableSpec::InitTests::IncluderTestManual.new
        	i.respond_to?(:includers).should == false
        end
        
        it 'initializes the includer after calling Componentable.init_includer_class' do
        	i = ComponentableSpec::InitTests::IncluderTestManual.new
        	i.respond_to?(:includer_test_manuals).should == false
        	
        	Origen::Componentable.init_includer_class(i)
        	i.instance_variable_defined?(:@_componentable_container).should == true
        	i._componentable_container.should == {}
        	i.respond_to?(:includer_test_manuals).should == true
        	i.includer_test_manuals.should == {}
        end
        
        it 'initializes automatically if the includer also includes Origen::Model' do
        	i = ComponentableSpec::InitTests::IncluderTestModel.new
        	
        	i.respond_to?(:includer_test_models).should == true
        	i.includer_test_models.should == {}
        end
        
        context 'with anonymous classes/modules' do
          it 'detects that it\'s an anonymous class and complains that the constant COMPONENTABLE_SINGLETON_NAME must be defined' do
            includer_class = Class.new do
              include Origen::Model
              include Origen::Componentable
            end
            
            expect { includer_class.new }.to raise_error Origen::Componentable::Error,
              /Anonymous classes that include the Componentable module must define COMPONENTABLE_SINGLETON_NAME/
          end
          
          it 'still complains if COMPONENTABLE_PLURAL_NAME is defined but COMPONENTABLE_SINGLETON_NAME is not' do
            includer_class = Class.new do
              include Origen::Model
              include Origen::Componentable
              
              self.const_set(:COMPONENTABLE_PLURAL_NAME, "plural_tester")
            end
            
            expect { includer_class.new }.to raise_error Origen::Componentable::Error,
              /Anonymous classes that include the Componentable module must define COMPONENTABLE_SINGLETON_NAME, even if COMPONENTABLE_PLURAL_NAME is defined/
          end
          
          it 'can initiailize an anonymous class with COMPONENTABLE_SINGLETON_NAME defined' do
            includer_class = Class.new do
              include Origen::Model
              include Origen::Componentable
              
              self.const_set(:COMPONENTABLE_SINGLETON_NAME, "singleton_tester")
            end
            
            i = includer_class.new
            expect(i).to respond_to(:singleton_testers)
          end
          
          it 'can initiailize an anonymous class with both COMPONENTABLE_SINGLETON_NAME and COMPONENTABLE_PLURAL_NAME defined' do
            includer_class = Class.new do
              include Origen::Model
              include Origen::Componentable
              
              self.const_set(:COMPONENTABLE_SINGLETON_NAME, "singleton_testa")
              self.const_set(:COMPONENTABLE_PLURAL_NAME, 'plural_testa')
            end
            
            i = includer_class.new
            expect(i).to respond_to(:plural_testa)
          end
          
          it 'complains if COMPONENTABLE_SINGLETON_NAME and COMPONENTABLE_PLURAL_NAME are the same' do
            includer_class = Class.new do
              include Origen::Model
              include Origen::Componentable
              
              self.const_set(:COMPONENTABLE_SINGLETON_NAME, 'same_name')
              self.const_set(:COMPONENTABLE_PLURAL_NAME, 'same_name')
            end
            
            expect { includer_class.new }.to raise_error Origen::Componentable::Error,
              /Componentable including class cannot define both COMPONENTABLE_SINGLETON_NAME and COMPONENTABLE_PLURAL_NAME to 'same_name'/
          end
        end
        
      end
      
      # Componetable.init_parent_class summary:
      #  initializes the includer class's compomentable methods on its
      #  parent.
      #  class parent_of_includer
      #    include Includer #=> includes Componentable
      #
      #    def initialize
      #      #=> includers #=> no method exception
      #      #=> self.respond_to?(:add_includer) #=> false
      #
      #      Origen::Componentable.init_parent_class(self) #=> this is auto-called if Origen::Model is included
      #      #=> includers #=> {}
      #      #=> self.respond_to?(:add_includer) #=> true
      #    ..
      describe 'Method: Componentable.init_parent_class' do
        
        it 'initially does not have a \'parent_no_model\' method' do
          c = ComponentableSpec::InitTests::ParentNoModel.new
          c.respond_to?(:parent_no_model).should == false
        end
        
        it 'initializes the includer setup after calling Componentable.init_parent_class' do
          c = ComponentableSpec::InitTests::ParentNoModelInit.new
          c.respond_to?(:to_include_with_model).should == true
          expect(c.to_include_with_model).to be_a(ComponentableSpec::InitTests::ToIncludeWithModel::ToIncludeWithModel)
        end
        
        it 'Bootstraps calling Componentable.init_parent_class if it includes Origen::Model, but there may be issues ' \
           'if the Componentable class does not include Origen::Model' do
           # Need to work on this since this is a bit dangerous. This ends up booting the parent class
           # but not boot the componentable class. So, the parent class has all the methods, but they'll all
           # fail at the componentable-class's level.
           # For now though, the following shows what will happen.
           c = ComponentableSpec::InitTests::Init_Parent_With_Model_Component_Without.new
           expect(c).to respond_to(:test_component)
           expect(c.test_component).to_not respond_to(:_componentable_container)
        end
        
        it 'Bootstraps calling Componentable.init_parent_class if it includes Origen::Model and works as expected' \
           'if the Componentable class does too' do
           c = ComponentableSpec::InitTests::Init_Parent_And_Component_With_Model.new
           
           c.respond_to?(:test_component).should == true
           expect(c.test_component).to be_a(ComponentableSpec::TestComponent::TestComponent)
        end
        
        context 'With anonymous classes' do
          it 'can initialize an anonymous parent without any additional setup' do
            parent_class = Class.new do
              include Origen::Model
              include ComponentableSpec::TestComponent
            end
            
            parent = parent_class.new
            expect(parent).to respond_to(:test_components)
            expect(parent).to respond_to(:test_component)
            expect(parent.test_component).to be_a(ComponentableSpec::TestComponent::TestComponent)
            expect(parent.test_components).to eql({})
          end
        end
        
        context 'with user-defined componentable names' do
          # These tests are mostly accomplished from the componentable_includer_init, but just double check here.
          
          it 'will initialize the API with COMPONENTABLE_SINGLETON_NAME defined' do
            fail
          end
          
          it 'will initialize the API with COMPONENTABLE_PLURAL_NAME defined' do
            fail
          end
          
          it 'will initialize the API with both COMPONENTABLE_SINGLETON_NAME and COMPONENTABLE_PLURAL_NAME defined' do
            fail
          end
        end
      end
    end
  end
  describe 'Includer API' do
    context 'testing with a dummy class' do
      before :context do
        # Create a dummy class to use as the includer
        @includer_class = Class.new do
          # Since we are making this class anonyomously, need to manually assign a name
          # if we do: ComponentableName = "APITester"
          # For some reason this adds it globally... not sure what that's about. So have to use const_set for this.
          self.const_set(:COMPONENTABLE_SINGLETON_NAME, "APITester")
          
          include Origen::Model
          include Origen::Componentable
        end
        
        # Instantiate the dummy class now. Assume that we are going though the Origen::Model initializer
        @includer = @includer_class.new
        
        # Make sure that we can access the compentable container instance variable.
        # If this doesn't work everything below will fail anyway, so may as well do it here before proceeding
        @includer.instance_variable_defined?(:@_componentable_container).should == true
        @includer.instance_variable_get(:@_componentable_container).should == {}
        
        @includer.respond_to?(:_componentable_container).should == true
        @includer._componentable_container.should == {}
      end
      
      describe 'Componentable method: add (stock :add method)' do
        it 'Adds a componentable item to its container (by class object)' do
          @includer.add(:test_string_by_class, class_name: ComponentableSpec::AddTest)
          
          @includer._componentable_container.keys.should == ["test_string_by_class"]
          @includer._componentable_container[:test_string_by_class].class.should == ComponentableSpec::AddTest
        end
        
        it 'Adds a componentable item to its container (by name of class as String)' do
          @includer.add(:test_object_by_string, class_name: 'ComponentableSpec::AddTest')
          
          @includer._componentable_container.keys.should == ["test_string_by_class", "test_object_by_string"]
          @includer._componentable_container[:test_string_by_class].class.should == ComponentableSpec::AddTest
        end
        
        it 'Adds a componentable item to its container (no classname, instantiates Origen::Component::Default Object)' do
          @includer.add(:test_default)
          
          @includer._componentable_container.has_key?('test_default').should == true
          @includer._componentable_container[:test_default].class.should == Origen::Component::Default
        end
        
        it 'Instantiates the given class and passes all options through' do
          @includer.add(:default, class_name: 'ComponentableSpec::AddTest', option1: 'option1', option2: 'options2')
          
          @includer._componentable_container.has_key?(:default).should == true
          @includer._componentable_container[:default].class.should == ComponentableSpec::AddTest
          
          @includer._componentable_container[:default].opts.should == {option1: 'option1', option2: 'options2'}
        end
        
        it 'Complains if the name of the component already exists' do
          expect {@includer.add(:default)}.to raise_error Origen::Componentable::NameInUseError, /api_tester name :default is already in use/
        end

        it 'Complains if the given class name cannot be found (given as a String)' do
          expect {@includer.add(:test_unknown, class_name: "UnknownClass")}.to raise_error Origen::Componentable::NameDoesNotExistError, /class_name option 'UnknownClass' cannot be found/
        end
        
      end
      
      describe 'Componentable method: list' do
        it 'list the names of all the added objects' do
          @includer.list.should == [
            "test_string_by_class",
            "test_object_by_string",
            "test_default",
            "default"
          ]
        end
        
        it 'returns an empty array if there are no items present' do
          includer = @includer_class.new
          includer.list.should == []
        end
      end
      
      describe 'Iterating through the componentable container' do
        it 'has an each method' do
          @includer.respond_to?(:each).should == true
        end
        
        it 'can iterate through the names and corresponding objects' do
          # Since the guts of all this is just a hash, really we just want to make sure
          # that @includer.each == @includer._componentable_container.each
          # So, we'll just make a new hash using the @includer.each method. If we iterate though
          # all the key/value pairs correctly, we'll just end up with the same hash as the componentable_container
          
          includer_each = Hash.new
          @includer.each do |name, obj|
            includer_each[name] = obj
          end
          
          includer_each.should == @includer._componentable_container
        end
      end
      
      describe 'Componentable method: has?' do
        it 'returns true if :name has been added' do
          @includer.has?(:default).should == true
        end
        
        it 'returns false if :name has not been added' do
          @includer.has?(:unknown).should == false
        end
      end

      describe 'Componentable method: instances_of' do
        it 'returns all of the component\'s names that are of class :klass where :klass is a class object' do
          @includer.instances_of(ComponentableSpec::AddTest).should == [
            "test_string_by_class",
            "test_object_by_string",
            "default"
          ]
          
          @includer.instances_of(Origen::Component::Default).should == ["test_default"]
        end
        
        it 'returns all of the component\'s names that are of class :klass where :klass is an instance of the class to search for' do
          @includer.instances_of(@includer._componentable_container[:default]).should == [
            "test_string_by_class",
            "test_object_by_string",
            "default"
          ]
        end
        
        it 'returns an empty array if no components match' do
          @includer.instances_of(String).should == []
          @includer.instances_of("test").should == []
        end
      end

      describe 'Componentable method: copy' do
        it 'copies component :name to component :name. Default is a deep copy (objects are NOT the same)' do
          @includer._componentable_container.key?(:default_copy).should == false
          @includer.copy(:default, :default_copy)
          
          @includer._componentable_container.key?(:default_copy).should == true
          @includer._componentable_container[:default_copy].class.should == ComponentableSpec::AddTest
          @includer._componentable_container[:default_copy].object_id.should_not == @includer._componentable_container[:default].object_id
        end
        
        it 'copies component :name to component :new_name, with option deep_copy: true' do
          @includer._componentable_container.key?(:default_deep_copy).should == false
          @includer.copy(:default, :default_deep_copy, deep_copy: true)
          
          @includer._componentable_container.key?(:default_deep_copy).should == true
          @includer._componentable_container[:default_deep_copy].class.should == ComponentableSpec::AddTest
          @includer._componentable_container[:default_deep_copy].object_id.should_not == @includer._componentable_container[:default].object_id
        end
        
        it 'copies component :name to component :new_name, with option deep_copy: false' do
          @includer._componentable_container.key?(:default_shallow_copy).should == false
          @includer.copy(:default, :default_shallow_copy, deep_copy: false)
          
          @includer._componentable_container.key?(:default_shallow_copy).should == true
          @includer._componentable_container[:default_shallow_copy].class.should == ComponentableSpec::AddTest
          @includer._componentable_container[:default_shallow_copy].object_id.should == @includer._componentable_container[:default].object_id
          @includer._componentable_container[:default_shallow_copy].object_id.should_not == @includer._componentable_container[:default_deep_copy].object_id
         end
        
        it 'complains if :name does not exist' do
          expect {@includer.copy(:no_name, :default_deep_copy_2)}.to raise_error Origen::Componentable::NameDoesNotExistError, /api_tester name :no_name does not exist/
        end
        
        it 'complains if :new_name does exist and :overwrite is not set (default)' do
          expect {@includer.copy(:default, :default_deep_copy)}.to raise_error Origen::Componentable::NameInUseError, /api_tester name :default_deep_copy is already in use/
        end
        
        it 'copies the component :name to :new_name, overwriting what is at :new_name, if :override is set' do
          @includer._componentable_container.key?(:default_copy).should == true
          old_object = @includer._componentable_container[:default_copy].object_id
          
          @includer.copy(:default, :default_copy, overwrite: true)
        end
      end
      
      describe 'Componentable method: move' do
        it 'moves component :name to component :new_name' do
          @includer._componentable_container.key?(:default_move).should == false
          @includer._componentable_container.key?(:default_copy).should == true
          old_id = @includer._componentable_container[:default_copy].object_id
          @includer.move(:default_copy, :default_move)
          
          @includer._componentable_container.key?(:default_move).should == true
          @includer._componentable_container.key?(:default_copy).should == false
          @includer._componentable_container[:default_move].class.should == ComponentableSpec::AddTest
          @includer._componentable_container[:default_move].object_id.should == old_id          
        end
        
        it 'complains if :name does not exist' do
          expect {@includer.move(:no_name, :default_move_2)}.to raise_error Origen::Componentable::NameDoesNotExistError, /api_tester name :no_name does not exist/
        end
        
        it 'complains if :new_name does exist and :overwrite is not set (default)' do
          expect {@includer.move(:default, :default_move)}.to raise_error Origen::Componentable::NameInUseError, /api_tester name :default_move is already in use/
        end
        
        it 'moves the component :name to :new_name, overwriting what is at :new_name, if :overwrite is set' do
          @includer._componentable_container.key?(:default_move).should == true
          @includer._componentable_container.key?(:default_deep_copy).should == true
          old_id = @includer._componentable_container[:default_deep_copy].object_id
          @includer.move(:default_deep_copy, :default_move, overwrite: true)

          @includer._componentable_container.key?(:default_move).should == true
          @includer._componentable_container.key?(:default_deep_copy).should == false
          @includer._componentable_container[:default_move].class.should == ComponentableSpec::AddTest
          @includer._componentable_container[:default_move].object_id.should == old_id
        end
      end
      
      describe 'Componentable method: delete' do
        it 'deletes the component :name' do
          @includer._componentable_container.should_not == {}
          @includer._componentable_container.key?(:default).should == true
          to_delete_object_id = @includer._componentable_container[:default].object_id
          deleted_object = @includer.delete(:default)
          
          deleted_object.class.should == ComponentableSpec::AddTest
          deleted_object.object_id.should == to_delete_object_id
          @includer._componentable_container.key?(:default).should == false
        end
        
        it 'complains if :name does not exist' do
          expect {@includer.delete(:no_name)}.to raise_error Origen::Componentable::NameDoesNotExistError, /api_tester name :no_name does not exist/
        end
      end
      
      describe 'Componentable method: delete!' do
        it 'also deletes the component :name' do
          @includer._componentable_container.should_not == {}
          @includer._componentable_container.key?(:default_move).should == true
          to_delete_object_id = @includer._componentable_container[:default_move].object_id
          deleted_object = @includer.delete!(:default_move)
          
          deleted_object.class.should == ComponentableSpec::AddTest
          @includer._componentable_container.key?(:default_move).should == false
        end
        
        it 'returns nil if the component :name does not exist (instead of complaining)' do
          @includer.delete!(:no_name).should == nil
        end
      end
      
      describe 'Componentable method: delete_all' do
        it 'deletes all components' do
          @includer._componentable_container.should_not == {}
          @includer.delete_all
          @includer._componentable_container.should == {}
        end
      end
    end
  end

  describe 'Parent API' do
    context 'with ComponentableTest class InitWithModel include TestComponent' do
      before :context do
        @parent = ComponentableSpec::ComponentableParentInitTest::InitWithModel.new
      end
      
      it 'has the componentable_test object' do
        @parent.respond_to?(:test_component).should == true
      end
      
      it 'has the test_component root method' do
        expect(@parent.test_component).to be_a(ComponentableSpec::TestComponent::TestComponent)
      end
      
      it 'the root method has _componentable_container available' do
        @parent.test_component.respond_to?(:_componentable_container).should == true
      end
      
      describe 'adding componentable_tests (stock :add method)' do
        [:test_component, :test_components, :add_test_component, :add_test_components].each do |method|
          it "adds the 'add methods' API: #{method}" do
            @parent.respond_to?(method).should == true
          end
        end
        
        it 'adds a component: test_component(name)' do
          added = @parent.test_component(:item1)
          expect(added).to be_a(Origen::Component::Default)
          expect(@parent.test_component._componentable_container[:item1]).to be_a(Origen::Component::Default)
        end
        
        it 'adds a component: test_components(name)' do
          added = @parent.test_components(:item2, class_name: ComponentableSpec::AddTest)
          expect(added).to be_a(ComponentableSpec::AddTest)
          expect(@parent.test_component._componentable_container[:item2]).to be_a(ComponentableSpec::AddTest)
        end
        
        it 'adds a component: add_test_component' do
          added = @parent.add_test_component(:item3)
          expect(added).to be_a(Origen::Component::Default)
          expect(@parent.test_component._componentable_container[:item3]).to be_a(Origen::Component::Default)
        end
        
        it 'adds a component: add_test_components' do
          added = @parent.add_test_components(:item4)
          expect(added).to be_a(Origen::Component::Default)
          expect(@parent.test_component._componentable_container[:item4]).to be_a(Origen::Component::Default)
        end
        
        it 'adds a component: test_component.add(name, ...)' do
          added = @parent.test_components(:item5)
          expect(added).to be_a(Origen::Component::Default)
          expect(@parent.test_component._componentable_container[:item5]).to be_a(Origen::Component::Default)
        end
        
        it 'complains if the component to add already exists' do
          expect { @parent.test_components(:item1) }.to raise_error Origen::Componentable::NameInUseError, /test_component name :item1 is already in use/
        end
        
      end
     
      describe 'listing and getting test_components' do
        [:list_test_components, :test_components].each do |method|
          it "adds the listing/getting API: #{method}" do
            @parent.respond_to?(method).should == true
          end
        end
        
        it 'gets a listing of component names: list_componentable_tests' do
          @parent.list_test_components.should == ["item1", "item2", "item3", "item4", "item5"]
        end
        
        #it 'gets a listing of component names: componentable_tests()' do
        #  @parent.test_components.should == ["item1", "item2", "item3", "item4", "item5"]
        #end
        
        it 'gets a the test component hash: test_components()' do
          expect(@parent.test_components).to eql @parent.test_component._componentable_container
        end
        
        it 'can get an individual test component using: test_components[name]' do
          expect(@parent.test_components[:item1]).to be_a Origen::Component::Default
        end
        
        it 'gets a listing of component names: componentable_test.list' do
          @parent.test_component.list.should == ["item1", "item2", "item3", "item4", "item5"]
        end
      end
      
      describe 'querying for item existance' do
        [:has_test_component?, :test_component?].each do |method|
          it 'adds the querying for item existance API: #{method}' do
            expect(@parent).to respond_to(method)
          end
        end
        
        it 'can query for a particular item\'s existance: test_component?' do
          expect(@parent.test_component?(:item1)).to eql(true)
        end
        
        it 'has :has_test_component aliased to :test_component?' do
          expect(@parent.method(:has_test_component?)).to eql(@parent.method(:test_component?))
        end
      end
      
      describe 'querying instances' do
        [:test_components_of_class, :test_components_instances_of, :test_components_of_type].each do |method|
          it 'adds the querying instances API: #{method}' do
            expect(@parent).to respond_to(method)
          end
        end
        
        it 'can query for class types: test_component_instances_of' do
          @parent.test_components_of_class(Origen::Component::Default).should == ["item1", "item3", "item4", "item5"]
        end
        
        it 'can query for class types: test_components.instances_of' do
          @parent.test_components_instances_of(ComponentableSpec::AddTest).should == ["item2"]
        end
        
        it 'has :test_components_of_class aliased to :test_components_of_type' do
          expect(@parent.method(:test_components_of_class)).to eql(@parent.method(:test_components_of_type))
        end
      end

      describe ':each and :select methods' do
        [:each_test_component, :all_test_components, :test_components,
         :select_test_components, :select_test_component
        ].each do |method|
          it "Adds the :each and :select API: #{method}" do
            expect(@parent).to respond_to(method)
          end
        end
        
        it 'iterates through test components: each_test_component' do
          h = Hash.new
          @parent.each_test_component do |name, instance|
            h[name] = instance
          end
          expect(h).to eql(@parent.test_component._componentable_container)
        end
        
        it 'has method :all_test_components aliased to method :each_test_component' do
          expect(@parent.method(:all_test_components)).to eql(@parent.method(:each_test_component))
        end
        
        it 'iterates through test components: test_components (with block)' do
          h = Hash.new
          @parent.test_components do |name, instance|
            h[name] = instance
          end
          expect(h).to eql(@parent.test_component._componentable_container)
        end
        
        it 'selects test components: select_test_components' do
          actual = @parent.test_component._componentable_container.select do |name, instance|
            name =~ /4/ || name =~ /5/
          end
          expected = @parent.select_test_components do |name, instance|
            name =~ /4/ || name =~ /5/
          end
          expect(expected).to eql(actual)
        end
        
        it 'has method :select_test_component aliased to method :select_test_components' do
          expect(@parent.method(:select_test_component)).to eql(@parent.method(:select_test_components))
        end
      end

      describe 'copying instances' do
        [:copy_test_component, :copy_test_components].each do |method|
          it "adds the API for copying instances: #{method}" do
            expect(@parent).to respond_to(method)
          end
        end
        
        it 'can copy an instance from one name to another: copy_test_component' do
          expect(@parent.test_component._componentable_container.key?(:item1)).to eql(true)
          expect(@parent.test_component._componentable_container.key?(:item1_copied)).to eql(false)
          obj_id = @parent.test_component._componentable_container[:item1].object_id
          
          @parent.copy_test_component(:item1, :item1_copied)
          
          expect(@parent.test_component._componentable_container.key?(:item1)).to eql(true)
          expect(@parent.test_component._componentable_container.key?(:item1_copied)).to eql(true)
          
          # This hsould be a deep copy
          expect(@parent.test_component._componentable_container[:item1_copied].object_id).to_not eql(obj_id)
        end
        
        it 'has method :copy_test_components aliased to method :copy_test_component' do
          expect(@parent.method(:copy_test_components)).to eql(@parent.method(:copy_test_component))
        end
      end

      describe 'moving instances' do
        [:move_test_component, :move_test_components].each do |method|
          it "adds the API for moving instances: #{method}" do
            expect(@parent).to respond_to(method)
          end
        end
        
        it 'can move an instance from one name to another: move_test_component' do
          expect(@parent.test_component._componentable_container.key?(:item1_copied)).to eql(true)
          expect(@parent.test_component._componentable_container.key?(:item1_moved)).to eql(false)
          obj_id = @parent.test_component._componentable_container[:item1_copied].object_id
          
          @parent.move_test_component(:item1_copied, :item1_moved)
          
          expect(@parent.test_component._componentable_container.key?(:item1_copied)).to eql(false)
          expect(@parent.test_component._componentable_container.key?(:item1_moved)).to eql(true)
          expect(@parent.test_component._componentable_container[:item1_moved].object_id).to eql(obj_id)
        end
        
        it 'has method :move_test_components aliased to method :move_test_component' do
          expect(@parent.method(:move_test_components)).to eql(@parent.method(:move_test_component))
        end
      end
      
      describe 'deleting instances' do
        [:delete_test_component, :delete_test_components, :remove_test_component, :remove_test_components,
         :delete_test_component!, :delete_test_components!, :remove_test_component!, :remove_test_components!,
        ].each do |method|
          it "adds the API for deleting instances: #{method}" do
            expect(@parent).to respond_to(method)
          end
        end
        
        it 'deletes an instance: delete_test_component' do
          expect(@parent.test_component._componentable_container.key?(:item1_moved)).to eql(true)
          expect(@parent.delete_test_component(:item1_moved)).to be_a(Origen::Component::Default)
          expect(@parent.test_component._componentable_container.key?(:item1_moved)).to eql(false)
        end
        
        it 'complains if the instance name is not found: delete_test_component' do
          expect {@parent.delete_test_component(:item1_moved)}.to raise_error(Origen::Componentable::NameDoesNotExistError)
        end
        
        it 'has method :delete_test_components aliased to method :delete_test_component' do
          expect(@parent.method(:delete_test_components)).to eql(@parent.method(:delete_test_component))
        end

        it 'has method :remove_test_component aliased to method :delete_test_component' do
          expect(@parent.method(:remove_test_component)).to eql(@parent.method(:delete_test_component))
        end
        
        it 'has method :remove_test_components aliased to method :delete_test_component' do
          expect(@parent.method(:remove_test_components)).to eql(@parent.method(:delete_test_component))
        end

        it 'deletes an instance or returns nil if the instance name is not found: delete_test_component!' do
          expect(@parent.test_component._componentable_container.key?(:item1_moved)).to eql(false)
          expect(@parent.delete_test_component!(:item1_moved)).to eql(nil)
        end
        
        it 'has method :delete_test_components! aliased to method :delete_test_component!' do
          expect(@parent.method(:delete_test_components!)).to eql(@parent.method(:delete_test_component!))
        end

        it 'has method :remove_test_component! aliased to method :delete_test_component!' do
          expect(@parent.method(:remove_test_component!)).to eql(@parent.method(:delete_test_component!))
        end
        
        it 'has method :remove_test_components! aliased to method :delete_test_component!' do
          expect(@parent.method(:remove_test_components!)).to eql(@parent.method(:delete_test_component!))
        end
      end
      
      describe 'deleting all instances' do
        [:delete_all_test_components, :clear_test_components, :remove_all_test_components].each do |method|
          it "adds the API for deleting all instances: #{method}" do
            expect(@parent).to respond_to(method)
          end
        end
        
        it 'deletes all the test components: delete_all_test_compoments' do
          expect(@parent.test_component._componentable_container).to_not eql({})
          @parent.delete_all_test_components
          expect(@parent.test_component._componentable_container).to eql({})
        end
        
        it 'has method :clear_test_components aliased to method :delete_all_test_component' do
          expect(@parent.method(:clear_test_components)).to eql(@parent.method(:delete_all_test_components))
        end
        
        it 'has method :remove_all_test_components aliased to method :delete_all_test_component' do
          expect(@parent.method(:remove_all_test_components)).to eql(@parent.method(:delete_all_test_components))
        end
      end
      
    end
  end
end
