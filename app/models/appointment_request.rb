class AppointmentRequest < ApplicationRecord
  belongs_to :nutritionist

  enum :status, { pending: 0, accepted: 1, rejected: 2, cancelled: 3 }

  # Explicit scopes for clarity (enums auto-generate these, but being explicit is better)
  scope :pending, -> { where(status: :pending) }
  scope :accepted, -> { where(status: :accepted) }
  scope :rejected, -> { where(status: :rejected) }
  scope :cancelled, -> { where(status: :cancelled) }

  validates :guest_name, presence: true
  validates :guest_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :requested_at, presence: true
  validate :requested_at_must_be_in_future, on: :create

  # Callbacks
  before_create :cancel_previous_pending_requests
  after_commit :send_status_notification, if: :saved_change_to_status?

  # Cancel conflicting requests when this one is accepted
  def accept!
    transaction do
      # Reload with lock to prevent race conditions
      self.class.lock.find(id)
      raise InvalidTransitionError, "Can only accept pending requests" unless pending?

      cancel_conflicting_requests!
      accepted!
    end
    # Email will be sent via after_commit callback
  end

  def reject!
    raise InvalidTransitionError, "Can only reject pending requests" unless pending?

    rejected!
    # Email will be sent via after_commit callback
  end

  class InvalidTransitionError < StandardError; end

  private

  def requested_at_must_be_in_future
    if requested_at.present? && requested_at <= Time.current
      errors.add(:requested_at, "must be in the future")
    end
  end

  # Rule: Guest can only have 1 pending request
  def cancel_previous_pending_requests
    previous_requests = AppointmentRequest
      .where(guest_email: guest_email, status: :pending)
      .where.not(id: id)

    previous_requests.find_each do |request|
      request.update!(status: :cancelled)
    end
  end

  # Rule: Accepting a request cancels all other pending requests for same slot
  def cancel_conflicting_requests!
    conflicting = AppointmentRequest
      .where(nutritionist_id: nutritionist_id, requested_at: requested_at, status: :pending)
      .where.not(id: id)

    conflicting.find_each do |request|
      request.update!(status: :cancelled)
    end
  end

  # Send appropriate email notification based on status change
  def send_status_notification
    case status
    when "accepted"
      AppointmentRequestMailer.accepted(self).deliver_later
    when "rejected"
      AppointmentRequestMailer.rejected(self).deliver_later
    when "cancelled"
      AppointmentRequestMailer.cancelled(self).deliver_later
    end
  end
end
