# frozen_string_literal: true

class Intake::DecisionReviewIntakeSerializer < Intake::IntakeSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :receipt_date do |object|
    object.detail.receipt_date
  end

  attribute :claimant do |object|
    object.detail.claimant_participant_id
  end

  attribute :veteran_is_not_claimant do |object|
    object.detail.veteran_is_not_claimant
  end

  attribute :payee_code do |object|
    object.detail.payee_code
  end

  attribute :legacy_opt_in_approved do |object|
    object.detail.legacy_opt_in_approved
  end
  attribute :legacy_appeals do |object|
    object.detail.serialized_legacy_appeals
  end

  attribute :ratings do |object|
    object.detail.serialized_ratings
  end

  attribute :veteran_invalid_fields do |object|
    object.detail.veteran_invalid_fields
  end

  attribute :request_issues do |object|
    object.detail.request_issues.active_or_ineligible.map(&:serialize)
  end

  attribute :active_nonrating_request_issues do |object|
    object.detail.active_nonrating_request_issues.map(&:serialize)
  end

  attribute :contestable_issues_by_date do |object|
    object.detail.contestable_issues.map(&:serialize)
  end

  attribute :veteran_valid do |object|
    object.detail.veteran&.valid?(:bgs)
  end
end
