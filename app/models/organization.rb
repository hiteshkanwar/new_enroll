class Organization
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include Mongoid::Versioning

  extend Mongorder

  ENTITY_KINDS = [
    "tax_exempt_organization",
    "c_corporation",
    "s_corporation",
    "partnership",
    "limited_liability_corporation",
    "limited_liability_partnership",
    "household_employer",
    "governmental_employer",
    "foreign_embassy_or_consulate"
  ]

  field :hbx_id, type: String

  # Registered legal name
  field :legal_name, type: String

  # Doing Business As (alternate name)
  field :dba, type: String

  # Federal Employer ID Number
  field :fein, type: String

  # Web URL
  field :home_page, type: String

  field :is_active, type: Boolean

  # User or Person ID who created/updated
  field :updated_by, type: BSON::ObjectId

  default_scope -> {order("legal_name ASC")}

  scope :employer_by_hbx_id, ->(employer_id) {
    where(hbx_id: employer_id, "employer_profile" => { "$exists" => true })
  }

  scope :has_broker_agency_profile, ->{ exists(broker_agency_profile: true) }
  #scope :by_broker_agency_profile, ->(broker_agency_profile_id) { where({'employer_profile.broker_agency_accounts.broker_agency_profile_id' => broker_agency_profile_id}).where({'employer_profile.broker_agency_accounts.is_active' => true}) }
  #scope :by_broker_role, -> (broker_role_id) { where({'employer_profile.broker_role_id' => broker_role_id})}
  scope :by_broker_agency_profile, -> (broker_agency_profile_id) {where(:'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, broker_agency_profile_id: broker_agency_profile_id } }) }
  scope :by_broker_role, -> (broker_role_id)                     {where(:'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, writing_agent_id: broker_role_id                   } })}

  scope :approved_broker_agencies,  -> { where("broker_agency_profile.aasm_state" => 'is_approved') }
  scope :broker_agencies_by_market_kind, -> (market_kind) { any_in("broker_agency_profile.market_kind" => market_kind) }

  scope :all_employers_by_plan_year_start_on,   ->(start_on){ unscoped.where(:"employer_profile.plan_years.start_on" => start_on) }

  scope :by_general_agency_profile, -> (general_agency_profile_id) { where(:'employer_profile.general_agency_accounts' => {:$elemMatch => { aasm_state: "active", general_agency_profile_id: general_agency_profile_id } }) }

  embeds_many :office_locations, cascade_callbacks: true, validate: true

  embeds_one :employer_profile, cascade_callbacks: true, validate: true
  embeds_one :broker_agency_profile, cascade_callbacks: true, validate: true
  embeds_one :general_agency_profile, cascade_callbacks: true, validate: true
  embeds_one :carrier_profile, cascade_callbacks: true, validate: true
  embeds_one :hbx_profile, cascade_callbacks: true, validate: true

  accepts_nested_attributes_for :office_locations, :employer_profile, :broker_agency_profile, :carrier_profile, :hbx_profile, :general_agency_profile

  validates_presence_of :legal_name, :fein, :office_locations #, :updated_by

  validates :fein,
    length: { is: 9, message: "%{value} is not a valid FEIN" },
    numericality: true,
    uniqueness: true

  validate :office_location_kinds

  index({ hbx_id: 1 }, { unique: true })
  index({ legal_name: 1 })
  index({ dba: 1 }, {sparse: true})
  index({ fein: 1 }, { unique: true })
  index({ is_active: 1 })

  # CarrierProfile child model indexes
  index({"carrier_profile._id" => 1}, { unique: true, sparse: true })

  # BrokerAgencyProfile child model indexes
  index({"broker_agency_profile._id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.aasm_state" => 1})
  index({"broker_agency_profile.primary_broker_role_id" => 1}, { unique: true, sparse: true })
  index({"broker_agency_profile.market_kind" => 1})

  # EmployerProfile child model indexes
  index({"employer_profile._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.aasm_state" => 1})

  index({"employer_profile.plan_years._id" => 1}, { unique: true, sparse: true })
  index({"employer_profile.plan_years.aasm_state" => 1})
  index({"employer_profile.plan_years.start_on" => 1})
  index({"employer_profile.plan_years.end_on" => 1})
  index({"employer_profile.plan_years.open_enrollment_start_on" => 1})
  index({"employer_profile.plan_years.open_enrollment_end_on" => 1})
  index({"employer_profile.plan_years.benefit_groups._id" => 1})
  index({"employer_profile.plan_years.benefit_groups.reference_plan_id" => 1})

  index({"employer_profile.workflow_state_transitions.transition_at" => 1,
         "employer_profile.workflow_state_transitions.to_state" => 1},
         { name: "employer_profile_workflow_to_state" })

  index({"employer_profile.broker_agency_accounts._id" => 1})
  index({"employer_profile.broker_agency_accounts.is_active" => 1,
         "employer_profile.broker_agency_accounts.broker_agency_profile_id" => 1 },
         { name: "active_broker_accounts_broker_agency" })
  index({"employer_profile.broker_agency_accounts.is_active" => 1,
         "employer_profile.broker_agency_accounts.writing_agent_id" => 1 },
         { name: "active_broker_accounts_writing_agent" })
  before_save :generate_hbx_id


  default_scope -> {order("legal_name ASC")}

  scope :employer_by_hbx_id, ->(employer_id) {
    where(hbx_id: employer_id, "employer_profile" => { "$exists" => true })
  }

  scope :has_broker_agency_profile, ->{ exists(broker_agency_profile: true) }
  scope :has_general_agency_profile, ->{ exists(general_agency_profile: true) }
  scope :by_broker_agency_profile, -> (broker_agency_profile_id) {where(:'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, broker_agency_profile_id: broker_agency_profile_id } }) }
  scope :by_broker_role, -> (broker_role_id)                     {where(:'employer_profile.broker_agency_accounts' => {:$elemMatch => { is_active: true, writing_agent_id: broker_role_id                   } })}

  scope :approved_broker_agencies,  -> { where("broker_agency_profile.aasm_state" => 'is_approved') }
  scope :broker_agencies_by_market_kind, -> (market_kind) { any_in("broker_agency_profile.market_kind" => market_kind) }


  scope :all_employers_by_plan_year_start_on,   ->(start_on){ unscoped.where(:"employer_profile.plan_years.start_on" => start_on) }
  scope :all_employers_renewing,                ->{ unscoped.any_in(:"employer_profile.plan_years.aasm_state" => PlanYear::RENEWING) }
  scope :all_employers_enrolled,                ->{ unscoped.where(:"employer_profile.plan_years.aasm_state" => "enrolled") }


  def generate_hbx_id
    write_attribute(:hbx_id, HbxIdGenerator.generate_organization_id) if hbx_id.blank?
  end

  # Strip non-numeric characters
  def fein=(new_fein)
    write_attribute(:fein, new_fein.to_s.gsub(/\D/, ''))
  end

  def primary_office_location
    office_locations.detect(&:is_primary?)
  end

  def self.search_by_general_agency(search_content)
    Organization.has_general_agency_profile.or({legal_name: /#{search_content}/i}, {"fein" => /#{search_content}/i})
  end

  def self.default_search_order
    [[:legal_name, 1]]
  end

  def self.search_hash(s_rex)
    search_rex = Regexp.compile(Regexp.escape(s_rex), true)
    {
      "$or" => ([
        {"legal_name" => search_rex}
      ])
    }
  end

  def self.valid_carrier_names
    Rails.cache.fetch("carrier-names-at-#{TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name if Plan.valid_shop_health_plans("carrier", org.carrier_profile.id).present?
        carrier_names
      end
    end
  end

  def self.valid_dental_carrier_names
    Rails.cache.fetch("dental-carrier-names-at-#{TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|

        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name if Plan.valid_shop_dental_plans("carrier", org.carrier_profile.id, 2016).present?
        carrier_names
      end
    end
  end

  def self.valid_carrier_names_filters
    Rails.cache.fetch("carrier-names-filters-at-#{TimeKeeper.date_of_record.year}", expires_in: 2.hour) do
      Organization.exists(carrier_profile: true).inject({}) do |carrier_names, org|
        carrier_names[org.carrier_profile.id.to_s] = org.carrier_profile.legal_name
        carrier_names
      end
    end
  end

  def self.valid_dental_carrier_names_for_options
    Organization.valid_dental_carrier_names.invert.to_a
  end

  def self.valid_carrier_names_for_options
    Organization.valid_carrier_names.invert.to_a
  end

  def office_location_kinds
    location_kinds = self.office_locations.select{|l| !l.persisted?}.flat_map(&:address).compact.flat_map(&:kind)
    # should validate only office location which are not persisted AND kinds ie. primary, mailing, branch
    return if no_primary = location_kinds.detect{|kind| kind == 'work' || kind == 'home'}
    unless location_kinds.empty?
      if location_kinds.count('primary').zero?
        errors.add(:base, "must select one primary address")
      elsif location_kinds.count('primary') > 1
        errors.add(:base, "can't have multiple primary addresses")
      elsif location_kinds.count('mailing') > 1
        errors.add(:base, "can't have more than one mailing address")
      end
      if !errors.any?# this means that the validation succeeded and we can delete all the persisted ones
        self.office_locations.delete_if{|l| l.persisted?}
      end
    end
  end


  class << self

    def build_query_params(search_params)
      query_params = []

      if !search_params[:q].blank?
        q = Regexp.new(Regexp.escape(search_params[:q].strip), true)
        query_params << {"legal_name" => q}
      end

      if !search_params[:languages].blank?
        query_params << {"broker_agency_profile.languages_spoken" => { "$in" => search_params[:languages]} }
      end

      if !search_params[:working_hours].blank?
        query_params << {"broker_agency_profile.working_hours" => eval(search_params[:working_hours])}
      end

      query_params
    end

    def search_agencies_by_criteria(search_params)
      query_params = build_query_params(search_params)
      if query_params.any?
        self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({ "$and" => build_query_params(search_params) })
      else
        self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop'])
      end
    end

    def broker_agencies_with_matching_agency_or_broker(search_params)
      if search_params[:q].present?
        orgs2 = self.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop']).where({
          "broker_agency_profile._id" => {
            "$in" => BrokerRole.agencies_with_matching_broker(search_params[:q])
          }
        })

        brokers = BrokerRole.brokers_matching_search_criteria(search_params[:q])
        if brokers.any?
          search_params.delete(:q)
          if search_params.empty?
            return filter_brokers_by_agencies(orgs2, brokers)
          else
            agencies_matching_advanced_criteria = orgs2.where({ "$and" => build_query_params(search_params) })
            return filter_brokers_by_agencies(agencies_matching_advanced_criteria, brokers)
          end
        end
      end

      self.search_agencies_by_criteria(search_params)
    end

    def filter_brokers_by_agencies(agencies, brokers)
      agency_ids = agencies.map{|org| org.broker_agency_profile.id}
      brokers.select{ |broker| agency_ids.include?(broker.broker_role.broker_agency_profile_id) }
    end
  end
end
