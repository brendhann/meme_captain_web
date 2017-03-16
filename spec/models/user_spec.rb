require 'rails_helper'

describe User do
  it { should validate_presence_of :email }
  it { should validate_uniqueness_of :email }
  it 'should validate that the email address is valid' do
  end

  it 'confirms the password' do
    expect do
      FactoryGirl.create(
        :user,
        password: 'password',
        password_confirmation: 'a different password'
      )
    end.to raise_error(
      ActiveRecord::RecordInvalid,
      "Validation failed: Password confirmation doesn't match Password"
    )
  end

  it { should have_many(:gend_images).through(:src_images) }
  it { should have_many :src_images }
  it { should have_many :src_sets }

  describe '.auth_case_insens' do
    let(:user_password) { 'some password' }
    let(:try_email) { 'does not exist' }
    let(:try_password) { 'try' }

    context 'when no emails are found' do
      it 'returns nil' do
        expect(User.auth_case_insens(try_email, try_password)).to be_nil
      end
    end

    context 'when one email is found' do
      before(:each) do
        @user = FactoryGirl.create(
          :user,
          password: user_password,
          password_confirmation: user_password
        )
      end

      let(:try_email) { @user.email }

      context 'when the password matches' do
        let(:try_password) { user_password }
        it 'finds the user' do
          expect(User.auth_case_insens(try_email, try_password)).to eq @user
        end
      end

      context 'when the password does not match' do
        it 'returns nil' do
          expect(User.auth_case_insens(try_email, try_password)).to be_nil
        end
      end
    end

    context 'when multiple emails are found' do
      let(:try_email) { @user.email }
      let(:user2_password) { 'some other password' }

      before(:each) do
        @user = FactoryGirl.create(
          :user,
          password: user_password,
          password_confirmation: user_password
        )
        @user2 = FactoryGirl.create(
          :user,
          email: @user.email.upcase,
          password: user2_password,
          password_confirmation: user2_password
        )
      end

      context 'when no passwords match' do
        it 'returns nil' do
          expect(User.auth_case_insens(try_email, try_password)).to be_nil
        end
      end

      context 'when the first password matches' do
        let(:try_password) { user_password }
        it 'find the first user' do
          expect(User.auth_case_insens(try_email, try_password)).to eq @user
        end
      end

      context 'when the last password matches' do
        let(:try_password) { user2_password }
        it 'find the second user' do
          expect(User.auth_case_insens(try_email, try_password)).to eq @user2
        end
      end
    end
  end

  describe '.for_auth' do
    it 'ignores case when finding emails' do
      user = FactoryGirl.create(:user)
      FactoryGirl.create(:user, email: user.email.upcase)
      expect(User.for_auth(user.email).count).to eq 2
    end
  end

  describe '#avatar_url' do
    it 'returns the avatar image url' do
      user = FactoryGirl.create(:user, email: 'test@test.com')
      expect(user.avatar_url(21)).to eq(
        'https://secure.gravatar.com/avatar/b642b4217b34b1e8d3bd915fc65c4452?s=21'
      )
    end

    it 'hashes the email without leading and trailing whitespace' do
      user = FactoryGirl.create(:user, email: ' test@test.com	')
      expect(user.avatar_url(21)).to eq(
        'https://secure.gravatar.com/avatar/b642b4217b34b1e8d3bd915fc65c4452?s=21'
      )
    end

    it 'hashes the email lowercase' do
      user = FactoryGirl.create(:user, email: 'TEST@test.com')
      expect(user.avatar_url(21)).to eq(
        'https://secure.gravatar.com/avatar/b642b4217b34b1e8d3bd915fc65c4452?s=21'
      )
    end
  end
end
