require "test_helper"

class AppointmentRequestTest < ActiveSupport::TestCase
  def setup
    @nutritionist = Nutritionist.create!(
      name: "Test Nutritionist",
      location: "Braga"
    )
  end

  test "should be valid with valid attributes" do
    request = AppointmentRequest.new(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 1.day.from_now
    )
    assert request.valid?
  end

  test "should require guest_email" do
    request = AppointmentRequest.new(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      requested_at: 1.day.from_now
    )
    assert_not request.valid?
    assert_includes request.errors[:guest_email], "can't be blank"
  end

  test "should validate email format" do
    request = AppointmentRequest.new(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "invalid-email",
      requested_at: 1.day.from_now
    )
    assert_not request.valid?
    assert_includes request.errors[:guest_email], "is invalid"
  end

  test "should require requested_at in future" do
    request = AppointmentRequest.new(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 1.hour.ago
    )
    assert_not request.valid?
    assert_includes request.errors[:requested_at], "must be in the future"
  end

  # CRITICAL BUSINESS RULE 1: Guest can only have 1 pending request
  test "creating new request cancels previous pending request from same guest" do
    first_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Same Guest",
      guest_email: "guest@example.com",
      requested_at: 2.days.from_now
    )

    assert_equal "pending", first_request.status

    # Create second request from same guest
    second_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Same Guest",
      guest_email: "guest@example.com",
      requested_at: 3.days.from_now
    )

    # First request should be cancelled
    assert_equal "cancelled", first_request.reload.status
    assert_equal "pending", second_request.status
  end

  # CRITICAL BUSINESS RULE 2: Accepting request cancels conflicting slots
  test "accepting request cancels other pending requests for same slot" do
    time_slot = 2.days.from_now.change(hour: 10, min: 0)

    request1 = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Guest 1",
      guest_email: "guest1@example.com",
      requested_at: time_slot
    )

    request2 = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Guest 2",
      guest_email: "guest2@example.com",
      requested_at: time_slot
    )

    # Accept first request
    request1.accept!

    # Second request should be cancelled
    assert_equal "accepted", request1.status
    assert_equal "cancelled", request2.reload.status
  end

  # EDGE CASE: Cannot accept already accepted request
  test "cannot accept already accepted request" do
    request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 2.days.from_now
    )

    request.accept!
    assert_equal "accepted", request.status

    # Try to accept again
    assert_raises(AppointmentRequest::InvalidTransitionError) do
      request.accept!
    end
  end

  # EDGE CASE: Cannot accept rejected request
  test "cannot accept rejected request" do
    request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 2.days.from_now
    )

    request.reject!
    assert_equal "rejected", request.status

    # Try to accept
    assert_raises(AppointmentRequest::InvalidTransitionError) do
      request.accept!
    end
  end

  # EDGE CASE: Cannot reject already rejected request
  test "cannot reject already rejected request" do
    request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 2.days.from_now
    )

    request.reject!
    assert_equal "rejected", request.status

    # Try to reject again
    assert_raises(AppointmentRequest::InvalidTransitionError) do
      request.reject!
    end
  end

  # EDGE CASE: Cannot reject accepted request
  test "cannot reject accepted request" do
    request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 2.days.from_now
    )

    request.accept!
    assert_equal "accepted", request.status

    # Try to reject
    assert_raises(AppointmentRequest::InvalidTransitionError) do
      request.reject!
    end
  end

  # MAILER TEST: Accepting request sends email
  test "accepting request sends accepted email after transaction" do
    request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 2.days.from_now
    )

    assert_enqueued_emails 1 do
      request.accept!
    end
  end

  # MAILER TEST: Rejecting request sends email
  test "rejecting request sends rejected email after transaction" do
    request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Test Guest",
      guest_email: "test@example.com",
      requested_at: 2.days.from_now
    )

    assert_enqueued_emails 1 do
      request.reject!
    end
  end

  # MAILER TEST: Creating new request sends cancellation email to previous guest
  test "creating new request sends cancellation email to previous guest" do
    first_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "First Guest",
      guest_email: "first@example.com",
      requested_at: 2.days.from_now
    )

    assert_equal "pending", first_request.status

    # Creating second request should send cancellation email for first
    assert_enqueued_emails 1 do
      AppointmentRequest.create!(
        nutritionist: @nutritionist,
        guest_name: "Second Guest",
        guest_email: "first@example.com",  # Same email
        requested_at: 3.days.from_now
      )
    end
  end

  # MAILER TEST: Accepting request sends cancellation emails to conflicting requests
  test "accepting request sends cancellation emails to conflicting requests" do
    time_slot = 2.days.from_now.change(hour: 10, min: 0)

    request1 = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Guest 1",
      guest_email: "guest1@example.com",
      requested_at: time_slot
    )

    request2 = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Guest 2",
      guest_email: "guest2@example.com",
      requested_at: time_slot
    )

    # Accepting request1 should send:
    # 1. Accepted email to guest1
    # 2. Cancelled email to guest2
    assert_enqueued_emails 2 do
      request1.accept!
    end
  end

  # SCOPE TEST: Verify pending scope works
  test "pending scope returns only pending requests" do
    pending_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Pending Guest",
      guest_email: "pending@example.com",
      requested_at: 2.days.from_now
    )

    accepted_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Accepted Guest",
      guest_email: "accepted@example.com",
      requested_at: 3.days.from_now
    )
    accepted_request.accept!

    pending_requests = AppointmentRequest.pending
    assert_includes pending_requests, pending_request
    assert_not_includes pending_requests, accepted_request
  end
end
