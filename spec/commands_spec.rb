require "spec_helper"

describe "Origen commands" do

  specify "-v works" do
    output = `origen -v`
    output.should include "Application: #{Origen.app.version}"
    output.should include "Origen: #{Origen.version}"

    if Origen.os.windows?
      output = `cd / && origen -v`
    else	
      output = `cd ~/ && origen -v`
    end
    output.should_not include "Application: #{Origen.app.version}"
    output.should include "Origen: #{Origen.version}"
  end

  specify "target works" do
    begin
      output = `origen t production`
      output = `origen t`
      output.should_not include "No target has been specified"
      output.should include "$nvm"
    ensure
      Origen.target.default = "debug"
    end
  end

end

module OrigenCommandSpec
  def add_dummy_command(name, command_group, options={})
    command.group.add(name, scope) do |cmd|
      cmd.body put "Hi from command: #{name}!"
    end
  end
end

# These tests will spec the internal API behavior. In order to do this without adding a bunch of complex plugin commands, we'll just dynamically build up a command listing and call
# the API methods directly.
# In essence, we will start just after the plugin commands would be loaded, except we will be build them in the specs.
# This is actually a user feature, so we get the benefit of testing that as well.
fdescribe 'Origen command interface internal API' do
  include_examples :commands_integration_spec
end

# For these, we will actually load in the test plugins and make sure we are building commands and calling them correctly when app/plugins, etc. is selected.
# However, you'll notice these tests are much simpler. The bulk of the API testing is done via the internal tests.
describe 'Origen command interface external' do
end

# These will tests that the Origen commands we use are stable. This is spec-ing namespaces, commands, and aliases.
# NOTE: functionality of the command is not done here. This is just checking that the command-line API is static and spec-ed.
describe 'Origen command line API' do
end

describe 'Origen command: version' do
end

describe 'Origen command: target' do
end

