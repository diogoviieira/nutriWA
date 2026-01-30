class AppointmentRequest < ApplicationRecord
  belongs_to :nutritionist

  enum :status, { pending: 0, accepted: 1, rejected: 2, cancelled: 3 }

  validates :guest_name, presence: true
  validates :guest_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :requested_at, presence: true
  validate :requested_at_must_be_in_future, on: :create

  # Callbacks
  before_create :cancel_previous_pending_requests

  # Cancel conflicting requests when this one is accepted
  def accept!
    transaction do
      cancel_conflicting_requests!
      accepted!
    end
  end

  def reject!
    rejected!
  end

  private

  def requested_at_must_be_in_future
    if requested_at.present? && requested_at <= Time.current
      errors.add(:requested_at, "must be in the future")
    end
  end

  # Rule: Guest can only have 1 pending request
  def cancel_previous_pending_requests
    AppointmentRequest
      .where(guest_email: guest_email, status: :pending)
      .update_all(status: :cancelled)
  end

  # Rule: Accepting a request cancels all other pending requests for same slot
  def cancel_conflicting_requests!
    AppointmentRequest
      .where(nutritionist_id: nutritionist_id, requested_at: requested_at, status: :pending)
      .where.not(id: id)
      .update_all(status: :cancelled)
  end
end
