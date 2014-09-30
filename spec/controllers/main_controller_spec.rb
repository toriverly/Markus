require 'spec_helper'
require 'markus_configurator'

describe MainController do

  describe 'POST #login_as' do

  # Required for REMOTE_USER config mocking
  RSpec.configure do |config|
    config.include MarkusConfigurator
  end

  # For AuthenticatedControllerTest stuff?
  # bypass cookie detection in the test because the command line, which is
  # running the test, cannot accept cookies
  before(:each) do
    request.cookies['cookieTest'] = 'fake cookie bypasses filter'
  end

    context 'when a valid admin' do
      let(:controller) { MainController.new }
      let(:admin) { build(:admin) }
      let(:student) { build(:student) }
      let(:otherAdmin) { build(:admin) }
      let(:otherStudent) { build(:student) }

      before :each do
        post :login, :user_login => admin.user_name,
             :user_password => 'nonEmptyPassword'
      end

      describe 'logs in' do
        it 'has session uid set correctly' do
          expect(admin.id).to eq session[:uid]
        end
      end

      describe 'attempts to switch roles' do
        context 'with empty data for effective user' do
          it 'does not switch role' do
            post :login_as, :effective_user_login => '',
                 :user_login => admin.user_name,
                 :admin_password => 'nonEmptyPassword',
                 :uid => admin.id, :timeout => 3.days.from_now
            expect(session[:real_uid]).to be_nil
          end
        end

        context 'with empty data for password' do
          it 'does not switch role' do
            post :login_as, :effective_user_login => student.user_name,
                 :user_login => admin.user_name,
                 :admin_password => '''',
                 :uid => admin.id, :timeout => 3.days.from_now
            expect(session[:real_uid]).to be_nil
          end
        end

        context 'when effective user is another admin' do
          it 'does not switch role' do
            post :login_as, :effective_user_login => otherAdmin.user_name,
                 :user_login => admin.user_name,
                 :admin_password => 'nonEmptyPassword',
                 :uid => admin.id, :timeout => 3.days.from_now
            expect(session[:real_uid]).to be_nil
          end
        end

        context 'when effective user is the same as current user' do
          it 'does not switch role' do
            post :login_as, :effective_user_login => admin.user_name,
                 :user_login => admin.user_name,
                 :admin_password => 'nonEmptyPassword',
                 :uid => admin.id, :timeout => 3.days.from_now
            expect(session[:real_uid]).to be_nil
          end
        end

        context 'with valid data for a role with lesser privileges' do
          it 'switches role' do
            post :login_as, :effective_user_login => student.user_name,
                 :user_login => admin.user_name,
                 :admin_password => 'nonEmptyPassword',
                 :uid => admin.id, :timeout => 3.days.from_now
            expect(session[:uid]).to eq student.id
            expect(session[:real_uid]).to eq admin.id
          end
        end
      end

      context 'when logged in as another user' do
        before :each do
          post :login_as,
               :effective_user_login => student.user_name,
               :user_login => admin.user_name,
               :admin_password => 'nonEmptyPassword',
               :uid => admin.id, :timeout => 3.days.from_now
        end

        # it 'renders the role_switch_handler template' do
        #   expect(response).to render_template(:role_switch_handler)
        # end

        describe 'attempts to switch roles' do
          context 'when effective user is another admin' do
            it 'does not switch role'
          end

          context 'when effective user is the same as current user' do
            it 'does not switch role'
          end

          context 'when effective user is the original user' do
            it 'drops back to original role'
          end

          context 'with valid data for a role with lesser privileges' do
            it 'switches role'
          end
        end

        context 'logs out' do
          it 'redirects to login page'
          it 'discards session info'
        end
      end
    end

    context 'when a valid student'
    context 'when a valid TA'
  end
end