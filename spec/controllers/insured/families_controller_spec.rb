require 'rails_helper'

RSpec.describe Insured::FamiliesController do
  context "set_current_user with no person" do
    let(:user) { FactoryGirl.create(:user, person: person) }
    let(:person) { FactoryGirl.create(:person) }

    before :each do
      sign_in user
    end

    it "should log the error" do
      expect(subject).to receive(:log) do |msg, severity|
        expect(severity[:severity]).to eq('error')
        expect(msg[:message]).to eq('@family was set to nil')
      end
      get :home
      expect(response).to redirect_to("/500.html")
    end

    it "should redirect" do
      get :home
      expect(response).to be_redirect
    end
  end
 context "set_current_user  as agent" do
    let(:user) { double("User", last_portal_visited: "test.com", id: 77, email: 'x@y.com', person: person) }
    let(:person) {FactoryGirl.create(:person)}

    it "should raise the error on invalid person_id" do
      allow(session).to receive(:[]).and_return(33)
      allow(person).to receive(:agent?).and_return(true)
      expect{get :home}.to raise_error
    end
  end
end

RSpec.describe Insured::FamiliesController do

  let(:hbx_enrollments) { double("HbxEnrollment") }
  let(:user) { double("User", last_portal_visited: "test.com") }
  let(:person) { double("Person", id: "test", addresses: [], no_dc_address: false, no_dc_address_reason: "" , has_active_consumer_role?: false) }
  let(:family) { double("Family", active_household: household) }
  let(:household) { double("HouseHold", hbx_enrollments: hbx_enrollments) }
  let(:addresses) { [double] }
  let(:family_members){[double("FamilyMember")]}
  let(:employee_roles) { [double("EmployeeRole")] }
  let(:consumer_role) { double("ConsumerRole") }
  # let(:coverage_wavied) { double("CoverageWavied") }
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, pre_event_sep_in_days: 30, post_event_sep_in_days: 0) }


  before :each do
    allow(hbx_enrollments).to receive(:order).and_return(hbx_enrollments)
    allow(hbx_enrollments).to receive(:waived).and_return([])
    allow(hbx_enrollments).to receive(:any?).and_return(false)
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:primary_family).and_return(family)
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    allow(person).to receive(:active_employee_roles).and_return(employee_roles)
    allow(consumer_role).to receive(:bookmark_url=).and_return(true)
    sign_in(user)
  end

  describe "GET home" do
    before :each do
      allow(family).to receive(:enrollments).and_return(hbx_enrollments)

      allow(family).to receive(:enrollments_for_display).and_return(hbx_enrollments)
      allow(family).to receive(:waivers_for_display).and_return(hbx_enrollments)
      allow(family).to receive(:coverage_waived?).and_return(false)
      allow(hbx_enrollments).to receive(:active).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:changing).and_return([])
      allow(user).to receive(:has_employee_role?).and_return(true)
      allow(user).to receive(:has_consumer_role?).and_return(true)
      allow(user).to receive(:last_portal_visited=).and_return("test.com")
      allow(user).to receive(:save).and_return(true)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(person).to receive(:addresses).and_return(addresses)
      allow(person).to receive(:has_multiple_roles?).and_return(true)
      allow(consumer_role).to receive(:save!).and_return(true)

      allow(family).to receive(:_id).and_return(true)
      allow(hbx_enrollments).to receive(:_id).and_return(true)
      allow(hbx_enrollments).to receive(:each).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:reject).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:inject).and_return(hbx_enrollments)
      allow(hbx_enrollments).to receive(:compact).and_return(hbx_enrollments)

      session[:portal] = "insured/families"
    end

    context "for SHOP market" do

      let(:employee_roles) { double }
      let(:employee_role) { [double("EmployeeRole")] }

      before :each do
        sign_in user
        allow(person).to receive(:has_active_employee_role?).and_return(true)
        allow(person).to receive(:active_employee_roles).and_return([employee_role])
        allow(family).to receive(:coverage_waived?).and_return(true)
        get :home
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render my account page" do
        expect(response).to render_template("home")
      end

      it "should assign variables" do
        expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
        expect(assigns(:hbx_enrollments)).to eq(hbx_enrollments)
        expect(assigns(:employee_role)).to eq(employee_role)
      end

      it "should get shop market events" do
        expect(assigns(:qualifying_life_events)).to eq QualifyingLifeEventKind.shop_market_events
      end
    end

    context "for IVL market" do
      let(:user) { double(identity_verified?: true, idp_verified?: true, last_portal_visited: '') }
      let(:employee_roles) { double }

      before :each do
        allow(person).to receive(:user).and_return(user)
        allow(person).to receive(:has_active_employee_role?).and_return(false)
        allow(person).to receive(:has_active_consumer_role?).and_return(true)
        allow(person).to receive(:active_employee_roles).and_return([])
        get :home
      end

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render my account page" do
        expect(response).to render_template("home")
      end

      it "should assign variables" do
        expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
        expect(assigns(:hbx_enrollments)).to eq(hbx_enrollments)
        expect(assigns(:employee_role)).to be_nil
      end

      it "should get individual market events" do
        expect(assigns(:qualifying_life_events)).to eq QualifyingLifeEventKind.individual_market_events
      end

      context "who has not passed ridp" do
        let(:user) { double(identity_verified?: false, last_portal_visited: '', idp_verified?: false) }

        before do
          allow(person).to receive(:user).and_return(user)
          allow(person).to receive(:has_active_employee_role?).and_return(false)
          allow(person).to receive(:has_active_consumer_role?).and_return(true)
          allow(person).to receive(:active_employee_roles).and_return([])
          get :home
        end

        it "should be a redirect" do
          expect(response).to have_http_status(:redirect)
        end
      end
    end
  end

  describe "GET manage_family" do
    let(:employee_roles) { double }
    let(:employee_role) { [double("EmployeeRole")] }

    before :each do
      allow(person).to receive(:active_employee_roles).and_return([employee_role])
      allow(family).to receive(:coverage_waived?).and_return(true)
      allow(family).to receive(:active_family_members).and_return(family_members)
    end

    it "should be a success" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family
      expect(response).to have_http_status(:success)
    end

    it "should render manage family section" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family
      expect(response).to render_template("manage_family")
    end

    it "should assign variables" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family
      expect(assigns(:qualifying_life_events)).to be_an_instance_of(Array)
      expect(assigns(:family_members)).to eq(family_members)
    end

    it "assigns variable to change QLE to IVL flow" do
      allow(person).to receive(:has_multiple_roles?).and_return(true)
      get :manage_family, market: "shop_market_events"
      expect(assigns(:manually_picked_role)).to eq "shop_market_events"
    end

    it "assigns variable to change QLE to Employee flow" do
      allow(person).to receive(:has_multiple_roles?).and_return(true)
      get :manage_family, market: "individual_market_events"
      expect(assigns(:manually_picked_role)).to eq "individual_market_events"
    end

    it "doesn't assign the variable to show different flow for QLE" do
      allow(person).to receive(:has_multiple_roles?).and_return(false)
      get :manage_family, market: "shop_market_events"
      expect(assigns(:manually_picked_role)).to eq nil
    end
  end

  describe "GET personal" do
    before :each do
      allow(family).to receive(:active_family_members).and_return(family_members)
      sign_in user
      get :personal
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render person edit page" do
      expect(response).to render_template("personal")
    end

    it "should assign variables" do
      expect(assigns(:family_members)).to eq(family_members)
    end
  end

  describe "GET inbox" do
    before :each do
      get :inbox
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should render inbox" do
      expect(response).to render_template("inbox")
    end

    it "should assign variables" do
      expect(assigns(:folder)).to eq("Inbox")
    end
  end


  describe "GET find_sep" do
    let(:user) { double(identity_verified?: true, idp_verified?: true) }
    let(:employee_roles) { double }
    let(:employee_role) { [double("EmployeeRole")] }

    before :each do
      allow(person).to receive(:user).and_return(user)
      allow(person).to receive(:has_active_employee_role?).and_return(false)
      allow(person).to receive(:has_active_consumer_role?).and_return(true)
      allow(person).to receive(:has_multiple_roles?).and_return(true)
      allow(person).to receive(:active_employee_roles).and_return(employee_role)
      get :find_sep, hbx_enrollment_id: "2312121212", change_plan: "change_plan"
    end

    it "should be a redirect to edit insured person" do
      expect(response).to have_http_status(:redirect)
    end

    context "with a person with an address" do
      let(:person) { double("Person", id: "test", addresses: true, no_dc_address: false, no_dc_address_reason: "") }

      it "should be a success" do
        expect(response).to have_http_status(:success)
      end

      it "should render my account page" do
        expect(response).to render_template("find_sep")
      end

      it "should assign variables" do
        expect(assigns(:hbx_enrollment_id)).to eq("2312121212")
        expect(assigns(:change_plan)).to eq('change_plan')
      end
    end
  end

  describe "POST record_sep" do
    before :each do
      @qle = FactoryGirl.create(:qualifying_life_event_kind)
      @family = FactoryGirl.build(:family, :with_primary_family_member)
      allow(person).to receive(:primary_family).and_return(@family)
    end

    context 'when its initial enrollment' do
      before :each do
        post :record_sep, qle_id: @qle.id, qle_date: Date.today
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_insured_group_selection_path({person_id: person.id, consumer_role_id: person.consumer_role.try(:id), enrollment_kind: 'sep'}))
      end
    end

    context 'when its change of plan' do

      before :each do
        allow(@family).to receive(:enrolled_hbx_enrollments).and_return([ double ])
        post :record_sep, qle_id: @qle.id, qle_date: Date.today
      end

      it "should redirect with change_plan parameter" do
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_insured_group_selection_path({person_id: person.id, consumer_role_id: person.consumer_role.try(:id), change_plan: 'change_plan', enrollment_kind: 'sep'}))
      end
    end
  end

  describe "GET check_qle_date" do

    before(:each) do
      sign_in(user)
    end

    it "renders the 'check_qle_date' template" do
      xhr :get, 'check_qle_date', :date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :format => 'js'
      expect(response).to have_http_status(:success)
    end

    describe "with valid params" do
      it "returns qualified_date as true" do
        xhr :get, 'check_qle_date', :date_val => (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y"), :format => 'js'
        expect(response).to have_http_status(:success)
        expect(assigns['qualified_date']).to eq(true)
      end
    end

    describe "with invalid params" do
      it "returns qualified_date as false for invalid future date" do
        xhr :get, 'check_qle_date', {:date_val => (TimeKeeper.date_of_record + 31.days).strftime("%m/%d/%Y"), :format => 'js'}
        expect(assigns['qualified_date']).to eq(false)
      end

      it "returns qualified_date as false for invalid past date" do
        xhr :get, 'check_qle_date', {:date_val => (TimeKeeper.date_of_record - 61.days).strftime("%m/%d/%Y"), :format => 'js'}
        expect(assigns['qualified_date']).to eq(false)
      end
    end

    context "GET check_qle_date" do
      let(:user) {FactoryGirl.create(:user)}
      let(:person) {FactoryGirl.build(:person)}
      let(:family) {FactoryGirl.build(:family)}
      before :each do
        allow(user).to receive(:person).and_return person
        allow(person).to receive(:primary_family).and_return family
      end

      context "normal qle event" do
        it "should return true" do
          date = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
          xhr :get, :check_qle_date, date_val: date, format: :js
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq true
        end

        it "should return false" do
          sign_in user
          date = (TimeKeeper.date_of_record + 40.days).strftime("%m/%d/%Y")
          xhr :get, :check_qle_date, date_val: date, format: :js
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq false
        end
      end

      context "special qle events which can not have future date" do
        it "should return true" do
          sign_in user
          date = (TimeKeeper.date_of_record + 8.days).strftime("%m/%d/%Y")
          xhr :get, :check_qle_date, date_val: date, qle_id: qle.id, format: :js
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq true
        end

        it "should return false" do
          sign_in user
          date = (TimeKeeper.date_of_record - 8.days).strftime("%m/%d/%Y")
          xhr :get, :check_qle_date, date_val: date, qle_id: qle.id, format: :js
          expect(response).to have_http_status(:success)
          expect(assigns(:qualified_date)).to eq false
        end

        it "should have effective_on_options" do
          sign_in user
          date = (TimeKeeper.date_of_record - 8.days).strftime("%m/%d/%Y")
          effective_on_options = [TimeKeeper.date_of_record, TimeKeeper.date_of_record - 10.days]
          allow(QualifyingLifeEventKind).to receive(:find).and_return(qle)
          allow(qle).to receive(:is_dependent_loss_of_coverage?).and_return(true)
          allow(qle).to receive(:employee_gaining_medicare).and_return(effective_on_options)
          xhr :get, :check_qle_date, date_val: date, qle_id: qle.id, format: :js
          expect(response).to have_http_status(:success)
          expect(assigns(:effective_on_options)).to eq effective_on_options
        end
      end
    end

    context "post unblock" do
      let(:family) {FactoryGirl.build(:family)}
      before :each do
        allow(Family).to receive(:find).and_return family
      end

      it "should be a success" do
        xhr :post, :unblock, id: family.id, format: :js
        expect(response).to have_http_status(:success)
        expect(assigns(:family).status).to eq "aptc_unblock"
      end
    end
  end
end
