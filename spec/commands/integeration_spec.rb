require 'origen/commands'

# Integration testing of command_group and commands
RSpec.shared_examples :commands_integration_spec do
  context 'with dummy commands' do
    before :context do
      # Load up some dummy commands
      #Origen::Commands.clear!
      
      # Set a dummy provider
      dummy = Origen::Commands::Provider.new(name: 'rspec')
      Origen::Commands.current_provider = dummy
      expect(Origen::Commands.current_provider).to eql(dummy)
      
      # Add two commands at the top level
      # Note, these will be added at the 'Origen' level.
      test_commands.add(:command1, :shared) do |cmd|
        cmd.aliases = [:cmd1]
      end
      test_commands.add(:command2, :shared) do |cmd|
        cmd.aliases = [:cmd2]
      end
      
      # Add two single namespaces. In each, but two more dummy commands as in the above.
      test_commands.with_nspace(:nspace_layer2_A) do |nspace|
        nspace.add(:command2a_1, :shared) do |cmd|
          cmd.aliases = [:cmd2a_1]
        end
        nspace.add(:command2a_2, :shared) do |cmd|
          cmd.aliases = [:cmd2a_2]
        end
      end
      test_commands.with_nspace(:nspace_layer2_B) do |nspace|
      end
      
      # Do the same things as above, but nest an additional layer.
      test_commands.with_nspace(:nspace_layer2_C) do |nspace|
        nspace.with_nspace(:nspace_layer3_A) do |n|
        end
        nspace.with_nspace(:nspace_layer3_B) do |n|
        end
      end
      
      # Just for fun, do the same thing again but with 10 layers.
      # At 10 layers deep, I'm going to assume the recursive nature of the command resolver works.
      test_commands.with_nspace(:nspace_layer2_D) do |n2|
        n2.with_nspace(:nspace_layer3_A) do |n3|
          n3.with_nspace(:nspace_layer4_A) do |n4|
            n4.with_nspace(:nspace_layer5_A) do |n5|
              n5.with_nspace(:nspace_layer6_A) do |n6|
                n6.with_nspace(:nspace_layer7_A) do |n7|
                  n7.with_nspace(:nspace_layer8_A) do |n8|
                    n8.with_nspace(:nspace_layer9_A) do |n9|
                      n9.with_nspace(:nspace_layer10_A) do |n10|
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      
      # Do something similiar now with a Commands::DummyProvider
    end

    describe 'finding commands' do
      describe '\'unnestd\' (1 namespace deep)' do
        it 'can find commands at the top namespace' do
          fail
        end

        it 'can find commands at the top namespace using they\'re aliases' do
          fail
        end

        it 'can find commands at the top namespaces using absolute referencing' do
          fail
        end

        it 'can find commands at the top namespaces using absolute referencing and aliases' do
          fail
        end
      end

      describe 'slightly nested (2 namespaces deep)' do
        it 'can find commands nested in namespaces' do
          fail
        end

        it 'can find commands nested in namespaces using abosolute referencing' do
          fail
        end
  
        it 'can find commands nested in namespaces using absolute referencing and namespace aliases' do
          fail
        end
      end

      describe 'slightly more nested (3 namespaces deep)' do
      end

      describe 'very nested (10 namespaces deep)' do
      end
    end

    describe 'finding namespaces' do
    end

    describe 'listing commands' do
    end
    
    describe 'finding and resolving command clobbering' do
    end
    
    describe 'finding and resolving namespace clobbering' do
    end

    after :context do
      # Clear the commands and reload Origen's
    end
  end
end 
