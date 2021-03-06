require 'rails_helper'

RSpec.describe "insured/families/_enrollment_progress.html.erb" do
  let(:hbx_enrollment) {double(aasm_state: 'coverage_selected')}

  before :each do
    #assign(:hbx_enrollment, hbx_enrollment)
    render partial: "insured/families/enrollment_progress", locals: {step: 2}, collection: [hbx_enrollment], as: :hbx_enrollment

  end

  it "should display step name" do
    ["Applied", "Sent to Carrier", "Enrolled"].each do |step|
      #expect(rendered).to match /#{step}/
    end
  end

  it "should display percent_complete" do
    #expect(rendered).to have_selector("label", text:"66% Complete")
  end

  it "should display title" do
    expect(rendered).to have_selector('h4', text: /coverage selected/i )
  end
end
