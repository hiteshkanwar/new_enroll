require 'rails_helper'

RSpec.describe "insured/families/home.html.erb" do
  before :each do
    stub_template "insured/families/_right_column.html.erb" => ''
    stub_template "insured/families/_qle_detail.html.erb" => ''
    stub_template "insured/families/_enrollment.html.erb" => ''
    stub_template "insured/families/_navigation.html.erb" => ''
    stub_template "insured/families/_shop_for_plans_widget.html.erb" => ''
    stub_template "insured/families/_apply_for_medicaid_widget.html.erb" => ''
    stub_template "insured/plan_shoppings/_help_with_plan.html.erb" => ''

    render file: "insured/families/home.html.erb"
  end

  it "should display the title" do
    expect(rendered).to have_selector('h1', text: 'My DC Health Link')
  end

  it "should have plan-summary area" do
    expect(rendered).to have_selector('div#plan-summary')
  end
end
