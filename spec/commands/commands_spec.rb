RSpec.shared_examples :command_handler_spec do

  it 'can instantiate a command handler' do
    fail
  end
  
  it 'can be instantiated with a name' do
    fail
  end
  
  it 'can query the current provider' do
    fail
  end
  
  it 'can set the current provider' do
    fail
  end
  
  it 'can list the current providers' do
    fail
  end
  
  it 'can add providers directly' do
    fail
  end
  
  it 'can add commands' do
    fail
  end
  
  it 'fails to add a command if the provider is not set' do
    fail
  end
  
  it 'will automatically register providers if commands are added from it' do
    fail
  end
  
  it 'will automatically make a command group from the registered provider' do
    fail
  end
  
  it 'can query providers within the specified scope' do
    fail
  end
  
  it 'can build a complete mapping of the current provider/command structure' do
    fail
  end
  
  it 'can set the current namespace' do
    fail
  end
  
  it 'can retreive the current namespace' do
    fail
  end
  
  it 'can run a block in the context of a namespace' do
    fail
  end
  
  it 'fails if the namespace context is not a provider' do
    # Recall that this boils down to just calling :with_nspace on the command group object.
    # For the handler, the namespaces correspond to a provider, and since we won't support orphaned namespaces
    # (namespace without a provider), just fail.
    fail
  end

end
