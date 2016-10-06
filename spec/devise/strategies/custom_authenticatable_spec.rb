RSpec.describe Devise::Models::CustomAuthenticatable do
  before(:each) do
    @resource = CustomAuthenticatableTestClass.new
    @it = Devise::Strategies::CustomAuthenticatable.new(env_with_params, :user)
  end

  describe "#authenticate!" do
    before(:each) do
      allow(@it).to receive(:password).and_return('password')
      allow(@it).to receive(:authentication_hash).and_return(password: 'password')
      allow(@it).to receive_message_chain("mapping.to.find_for_authentication").and_return(@resource)

      allow(@it).to receive(:validate) do |resource, &block|
        expect(resource).to eq @resource
        block.call
      end
    end

    it "should pass to another strategy if #valid_for_custom_authentication? is not defined" do
      @resource.instance_eval('undef :valid_for_custom_authentication?')

      expect(@resource).to receive(:after_custom_authentication).never
      expect(@it).to receive(:validate).never
      expect(@it).to receive(:pass).once.and_return('skip')
      expect(@it.authenticate!).to eq 'skip'
    end

    it "should pass to another strategy if #skip_custom_strategies called in #valid_for_custom_authentication?" do
      expect(@resource).to receive(:valid_for_custom_authentication?).with('password') do
        @resource.skip_custom_strategies
      end
      expect(@resource).to receive(:after_custom_authentication).never
      expect(@it).to receive(:success!).never
      @it.authenticate!
    end

    it "should fail if #valid_for_custom_authentication? is defined and return false" do
      expect(@resource).to receive(:valid_for_custom_authentication?).with('password').and_return(false)
      expect(@resource).to receive(:after_custom_authentication).never
      expect(@it).to receive(:pass).never
      expect(@it).to receive(:success!).never
      @it.authenticate!
    end

    it "should return with success! if #valid_for_custom_authentication? is defined and return true" do
      expect(@resource).to receive(:valid_for_custom_authentication?).with('password').and_return(true)
      expect(@it).to receive(:pass).never
      expect(@resource).to receive(:after_custom_authentication).once
      expect(@it).to receive(:success!).once.with(@resource).and_return('success')
      expect(@it.authenticate!).to eq 'success'
    end

  end

end
