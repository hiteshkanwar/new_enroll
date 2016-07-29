require 'rails_helper'

describe EmployerProfile, "Test seed file" do

  describe "Call Rake task for seed date #Employer" do
    it "Run seed file " do
      system "bundle exec rake broker:employer RAILS_ENV=test"
    end  

    it "Check Organization create by seed file" do
      expect(Organization.all.count).to eq(55)
    end  

    it "Check Employer profile create by seed file" do
      expect(EmployerProfile.all.count).to eq(50)
    end  

    it "Check Broker Agency profile create by seed file" do
      expect(BrokerAgencyProfile.all.count).to eq(5)
    end 

    it "Check Plan create by seed file" do
      expect(Plan.all.count).to eq(50)
    end 

    it "Check Employee create by seed file" do
      expect(CensusEmployee.all.count).to eq(1000)
    end 

    it "Check Employee create by seed file" do
      expect(CarrierProfile.all.count).to eq(50)
    end 
  end
end  