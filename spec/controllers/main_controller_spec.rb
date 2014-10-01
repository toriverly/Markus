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
  # before(:each) do
  #   request.cookies['cookieTest'] = 'fake cookie bypasses filter'
  # end

    context 'when a valid admin' do
      let(:admin) { build(:admin) }
      let(:otherAdmin) { build(:admin) }
      let(:student) { build(:student) }
      let(:otherStudent) { build(:student) }

      before :each do
        post :login, :user_login => admin.user_name,
             :user_password => 'nonEmptyPassword'
      end

      it 'has session uid set correctly' do
        expect(session[:uid]).to eq admin.id
      end

      shared_examples 'failed role switch' do
        let(:real_uid) { session[:real_uid] }

        before do
          post :login_as, :effective_user_login => effective_user_name,
               :user_login => current_user.user_name,
               :admin_password => password,
               :uid => current_user.id, :timeout => 3.days.from_now
        end

        it 'does NOT switch role' do
          expect(session[:uid]).to eq current_user.id
          expect(session[:real_uid]).to eq real_uid
        end
      end


      shared_examples 'successful role switch' do
        before do
          post :login_as, :effective_user_login => effective_user.user_name,
               :user_login => current_user.user_name,
               :admin_password => 'nonEmptyPassword',
               :uid => current_user.id, :timeout => 3.days.from_now
        end

        it 'switches role' do
          expect(session[:uid]).to eq effective_user.id
          expect(session[:real_uid]).to eq real_uid
        end

        it 'redirects to index'
        # redirect_to :action => 'index'
      end

      context 'when attempting to switch roles' do
        context 'with empty data for effective user' do
          include_examples 'failed role switch' do
            let(:current_user) { admin }
            let(:effective_user_name) { '' }
            let(:password) { 'nonEmptyPassword' }
          end
        end

        context 'with empty data for password' do
          include_examples 'failed role switch' do
            let(:current_user) { admin }
            let(:effective_user_name) { student.user_name }
            let(:password) { '' }
          end
        end

        context 'when effective user is another admin' do
          include_examples 'failed role switch' do
            let(:current_user) { admin }
            let(:effective_user_name) { otherAdmin.user_name }
            let(:password) { 'nonEmptyPassword' }
          end
        end

        context 'when effective user is the same as current user' do
          include_examples 'failed role switch' do
            let(:current_user) { admin }
            let(:effective_user_name) { admin.user_name }
            let(:password) { 'nonEmptyPassword' }
          end
        end

        context 'with valid data for a role with lesser privileges' do
          include_examples 'successful role switch' do
            let(:current_user) { admin }
            let(:effective_user) { student }
            let(:real_uid) { admin.id }
          end
        end
      end

      context 'when role has been switched another user' do
        before :each do
          post :login_as,
               :effective_user_login => student.user_name,
               :user_login => admin.user_name,
               :admin_password => 'nonEmptyPassword',
               :uid => admin.id, :timeout => 3.days.from_now
        end

        xit 'renders the role_switch_handler template' do
          expect(response).to render_template(:role_switch_handler)
        end

        context 'when attempting to switch roles' do
          context 'when effective user is another admin' do
            include_examples('failed role switch') do
              let(:current_user) { student }
              let(:effective_user_name) { otherAdmin.user_name }
              let(:password) { 'nonEmptyPassword' }
            end
          end

          context 'when effective user is the same as current user' do
            include_examples 'failed role switch' do
              let(:current_user) { student }
              let(:effective_user_name) { student.user_name }
              let(:password) { 'nonEmptyPassword' }
            end
          end

          context 'when effective user is the original user' do
            include_examples 'successful role switch' do
              let(:current_user) { student }
              let(:effective_user) { admin }
              let(:real_uid) { nil }
            end
          end

          context 'with valid data for a role with lesser privileges' do
            include_examples 'successful role switch' do
              let(:current_user) { student }
              let(:effective_user) { otherStudent }
              let(:real_uid) { admin.id }
            end
          end
        end

        context 'when logged out' do
          before :each do
            # TODO: should this be student or admin?
            get :logout, :uid => admin.id, :timeout => 3.days.from_now
          end

          xit 'redirects to login page' do
            expect(controller).to redirect_to :action => 'login'
          end

          it 'discards session info' do
            expect(session[:uid]).to be_nil
            expect(session[:real_uid]).to be_nil
          end
        end
      end
    end

    context 'when a valid student'
    context 'when a valid TA'
  end
end