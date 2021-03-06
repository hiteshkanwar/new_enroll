module Insured::FamiliesHelper

  def current_premium hbx_enrollment
    if hbx_enrollment.kind == 'employer_sponsored'
      hbx_enrollment.total_employee_cost
    else
      hbx_enrollment.total_premium > hbx_enrollment.applied_aptc_amount.to_f ? hbx_enrollment.total_premium - hbx_enrollment.applied_aptc_amount.to_f : 0
    end
  end

  def hide_policy_selected_date?(hbx_enrollment)
    return true if hbx_enrollment.created_at.blank?
    return true if hbx_enrollment.benefit_group.present? && hbx_enrollment.benefit_group.is_congress && hbx_enrollment.created_at <= Time.zone.parse("2015-11-09 14:00:00").utc
    return true if !hbx_enrollment.consumer_role_id.blank? && hbx_enrollment.created_at <= Time.zone.parse("2015-10-13 14:00:00").utc
    false
  end

  def shift_purchase_time(policy)
    policy.created_at.in_time_zone('Eastern Time (US & Canada)') 
  end

  def format_policy_purchase_date(policy)
    format_date(shift_purchase_time(policy))
  end

  def format_policy_purchase_time(policy)
    shift_purchase_time(policy).strftime("%-I:%M%p")
  end

  def render_plan_type_details(plan)
    plan_details = [ plan.try(:plan_type).try(:upcase) ].compact

    metal_level = display_dental_metal_level(plan)

    if plan_level = plan.try(:metal_level).try(:humanize)
      plan_details << "<span class=\"#{plan_level.try(:downcase)}-icon\">#{metal_level}</span>"
    end

    if plan.try(:nationwide)
      plan_details << "NATIONWIDE NETWORK"
    end

    plan_details.inject([]) do |data, element|
      data << "<label>#{element}</label>"
    end.join("&nbsp<label class='separator'></label>").html_safe
  end

  def qle_link_generater(qle, index)
    options = {class: 'qle-menu-item'}
    data = {
      title: qle.title, id: qle.id.to_s, label: qle.event_kind_label,
      post_event_sep_in_days: qle.post_event_sep_in_days,
      pre_event_sep_in_days: qle.pre_event_sep_in_days,
      date_hint: qle.date_hint, is_self_attested: qle.is_self_attested,
      current_date: TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    }

    if qle.tool_tip.present?
      data.merge!(toggle: 'tooltip', placement: index > 1 ? 'top' : 'bottom')
      options.merge!(data: data, title: qle.tool_tip)
    else
      options.merge!(data: data)
    end
    link_to qle.title, "javascript:void(0)", options
  end

  def generate_options_for_effective_on_kinds(effective_on_kinds, qle_date)
    return [] if effective_on_kinds.blank?

    options = []
    effective_on_kinds.each do |kind|
      case kind
      when 'date_of_event'
        options << [qle_date.to_s, kind]
      when 'fixed_first_of_next_month'
        options << [(qle_date.end_of_month + 1.day).to_s, kind]
      end
    end

    options
  end

  def show_employer_panel?(person, hbx_enrollments)
    return false if person.blank? or !person.has_active_employee_role?
    return true if hbx_enrollments.blank? or hbx_enrollments.shop_market.blank?

    if hbx_enrollments.shop_market.entries.map(&:employee_role_id).include? person.active_employee_roles.first.id
      false
    else
      true
    end
  end

  def has_writing_agent?(employee_role)
    employee_role.employer_profile.active_broker_agency_account.writing_agent rescue false
  end
end
