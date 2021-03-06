And /^Hbx admin should see the link of announcements and click$/ do
  expect(page).to have_content("Announcements")
  click_link 'Announcements'
end

Then /^Hbx admin should see the page of announcements$/ do
  expect(page).to have_content("Current Announcements")
  expect(page).to have_content("Msg Start Date")
end

When(/Hbx admin enter announcement info$/) do
  fill_in 'announcement[content]', with: 'msg content'
  fill_in 'jq_datepicker_ignore_announcement[start_date]', with: (TimeKeeper.date_of_record - 5.days).to_s
  fill_in 'jq_datepicker_ignore_announcement[end_date]', with: (TimeKeeper.date_of_record + 5.days).to_s
  find('#announcement_audiences_ivl').click
  find('.interaction-click-control-create-announcement').click
end

Then(/Hbx admin should see the current announcement/) do
  expect(page).to have_content('msg content')
  expect(page).to have_content('IVL')
end

Then(/^.+ should see announcement$/) do
  expect(page).to have_content('Announcement')
  expect(page).to have_content('msg content')
end

Given(/^Consumer role exists$/) do
  user = FactoryGirl.create :user, :with_family, :consumer, email: 'consumer@dc.gov', password: '1qaz@WSX', password_confirmation: '1qaz@WSX'
end

Given(/^Employer role exists$/) do
  employer_profile = FactoryGirl.create :employer_profile
  user = FactoryGirl.create :user, :with_family, :employer_staff, email: 'employer@dc.gov', password: '1qaz@WSX', password_confirmation: '1qaz@WSX'
  FactoryGirl.create :employer_staff_role, person: user.person, employer_profile_id: employer_profile.id
end

Then(/^Employer should not see announcement$/) do
  expect(page).not_to have_content('msg content')
end

When(/^Employer login$/) do
  visit "/"
  click_link "Employer Portal"
  find('.interaction-click-control-sign-in-existing-account').click

  fill_in "user[email]", :with => 'employer@dc.gov'
  find('#user_email').set('employer@dc.gov')
  fill_in "user[password]", :with => '1qaz@WSX'
  fill_in "user[email]", :with => 'employer@dc.gov' unless find(:xpath, '//*[@id="user_email"]').value == 'employer@dc.gov'
  find('.interaction-click-control-sign-in').click
end

Given(/^Announcement prepared for Consumer role$/) do
  FactoryGirl.create :announcement, audiences: ['IVL'], content: 'msg content'
end

When(/^Consumer login$/) do
  visit "/"
  click_link "Consumer/Family Portal"
  find('.interaction-click-control-sign-in-existing-account').click

  fill_in "user[email]", :with => 'consumer@dc.gov'
  find('#user_email').set('consumer@dc.gov')
  fill_in "user[password]", :with => '1qaz@WSX'
  fill_in "user[email]", :with => 'consumer@dc.gov' unless find(:xpath, '//*[@id="user_email"]').value == 'consumer@dc.gov'
  find('.interaction-click-control-sign-in').click
end
