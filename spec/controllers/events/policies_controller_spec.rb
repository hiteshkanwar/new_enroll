require "rails_helper"

describe Events::PoliciesController do
  describe "providing a resource" do
    let(:policy) { double }
    let(:policy_id) { "the hbx id for this policy" }
    let(:rendered_template) { double }
    let(:di) { double }
    let(:channel) { double(:default_exchange => exchange, :close => nil) }
    let(:reply_to_key) { "some queue name" }
    let(:exchange) { double }
    let(:connection) { double(:create_channel => channel) }
    let(:props) { double(:headers => {:policy_id => policy_id}, :reply_to => reply_to_key) }

    before :each do
      allow(HbxEnrollment).to receive(:by_hbx_id).with(policy_id).and_return(found_policys)
      allow(controller).to receive(:render_to_string).with(
        "events/hbx_enrollment/policy", {:formats => ["xml"], :locals => {
         :hbx_enrollment => policy
        }}).and_return(rendered_template)
    end

    describe "for an existing policy" do
      let(:found_policys) { [policy] }

      it "should send out a message to the bus with the rendered policy object" do
        expect(exchange).to receive(:publish).with(rendered_template, {
          :routing_key => reply_to_key,
          :headers => {
            :policy_id => policy_id,
            :return_status => "200"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end

    describe "for a policy which doesn't exist" do
      let(:found_policys) { [] }

      it "should send out a message to the bus with no policy object" do
        expect(exchange).to receive(:publish).with("", {
          :routing_key => reply_to_key,
          :headers => {
            :policy_id => policy_id,
            :return_status => "404"
          }       
        })
        controller.resource(connection, di, props, "")
      end
    end
  end

end
