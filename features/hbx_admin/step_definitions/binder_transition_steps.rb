module BinderTransitionWorld
  include ApplicationHelper

  def employer(*traits)
    attributes = traits.extract_options!
    @employer ||= FactoryGirl.create :employer, *traits, attributes
  end
end
World(BinderTransitionWorld)

Given(/^a new employer, with insured employees, exists$/) do
  employer :with_insured_employees
end

Given(/^the HBX admin visits the Dashboard page$/) do
  visit exchanges_hbx_profiles_root_path
end

And(/^the HBX admin clicks the Binder Transition tab$/) do
  page.find('.interaction-click-control-binder-transition').click
  page.find(".title-inline").should have_content("Binder Transition Information")
end

Then(/^the HBX admin sees a checklist$/) do |checklist|
  expect(page.find(".eligibility-rule").text).to eq eligibility_criteria(employer.employer_profile).gsub("<br>", " ")
end

When(/^the HBX admin selects the employer to confirm$/) do
  sleep 1
  page.find("#employer_profile_id_#{employer.employer_profile.id.to_s}").click
end

Then(/^the initiate "([^"]*)" button will be active$/) do |arg1|
  expect(find("#binderSubmit")["disabled"]).to eq false # binder paid button should be enabled at this point as we selected an employer
end

And(/^the HBX admin clicks the "([^"]*)" button$/) do |arg1|
  click_button arg1
  sleep 1
end

Then(/^then the Employer’s state transitions to "([^"]*)"$/) do |arg1|
  employer.reload
  expect(employer.employer_profile.aasm_state.titleize).to eq arg1
end

Given(/^the employer meets requirements$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the HBX admin has confirmed requirements for the employer$/) do
  step "the HBX admin clicks the Binder Transition tab"
  step "the HBX admin selects the employer to confirm"
end

When(/^the employer remits initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the DCHBX confirms binder payment has been received by third\-party processor$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the HBX admin has verified new \(initial\) Employer meets minimum participation requirements \((\d+)\/(\d+) rule\)$/) do |arg1, arg2|
  expect(page.find(".eligibility-rule").text).to include(participation_rule(employer.employer_profile))
end

When(/^a sufficient number of 'non\-owner' employee\(s\) have enrolled and\/or waived in Employer\-sponsored benefits$/) do
  expect(page.find(".eligibility-rule").text).to include(non_owner_participation_rule(employer.employer_profile))
end

Given(/^the employer has remitted the initial binder payment$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the Group XML is generated for the Employer$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^the employer is renewing$/) do
  py = employer.employer_profile.plan_years.last
  py.aasm_state = "renewing_enrolling"
  py.save
end

Then(/^the HBX\-Admin can utilize the “Transmit EDI” button$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
