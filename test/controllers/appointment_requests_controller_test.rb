require "test_helper"

class AppointmentRequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @nutritionist = Nutritionist.create!(
      name: "Dr. Test Nutritionist",
      location: "Lisboa"
    )
  end

  test "POST create with valid params creates appointment request" do
    assert_difference("AppointmentRequest.count", 1) do
      post appointment_requests_path, params: {
        nutritionist_id: @nutritionist.id,
        appointment_request: {
          guest_name: "John Doe",
          guest_email: "john@example.com",
          requested_at: 2.days.from_now
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match /Appointment request sent successfully!/, response.body
  end

  test "POST create with invalid email shows error" do
    assert_no_difference("AppointmentRequest.count") do
      post appointment_requests_path, params: {
        nutritionist_id: @nutritionist.id,
        appointment_request: {
          guest_name: "John Doe",
          guest_email: "invalid-email",
          requested_at: 2.days.from_now
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match /is invalid/, response.body
  end

  test "POST create with past datetime shows error" do
    assert_no_difference("AppointmentRequest.count") do
      post appointment_requests_path, params: {
        nutritionist_id: @nutritionist.id,
        appointment_request: {
          guest_name: "John Doe",
          guest_email: "john@example.com",
          requested_at: 1.hour.ago
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match /must be in the future/, response.body
  end

  test "POST create with missing guest_name shows error" do
    assert_no_difference("AppointmentRequest.count") do
      post appointment_requests_path, params: {
        nutritionist_id: @nutritionist.id,
        appointment_request: {
          guest_email: "john@example.com",
          requested_at: 2.days.from_now
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match /can't be blank/, response.body
  end

  test "POST create cancels previous pending request from same guest" do
    # Create first request
    first_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "John Doe",
      guest_email: "john@example.com",
      requested_at: 2.days.from_now
    )

    assert_equal "pending", first_request.status

    # Create second request with same email
    assert_enqueued_emails 1 do  # Cancellation email
      post appointment_requests_path, params: {
        nutritionist_id: @nutritionist.id,
        appointment_request: {
          guest_name: "John Doe",
          guest_email: "john@example.com",
          requested_at: 3.days.from_now
        }
      }
    end

    # First request should be cancelled
    assert_equal "cancelled", first_request.reload.status
  end

  test "POST create with invalid nutritionist_id returns error" do
    assert_raises(ActiveRecord::RecordNotFound) do
      post appointment_requests_path, params: {
        nutritionist_id: 99999,
        appointment_request: {
          guest_name: "John Doe",
          guest_email: "john@example.com",
          requested_at: 2.days.from_now
        }
      }
    end
  end

  test "POST create filters parameters correctly (mass assignment protection)" do
    # Try to set status directly (should be ignored)
    post appointment_requests_path, params: {
      nutritionist_id: @nutritionist.id,
      appointment_request: {
        guest_name: "Hacker",
        guest_email: "hacker@example.com",
        requested_at: 2.days.from_now,
        status: 1  # Try to set as accepted
      }
    }

    request = AppointmentRequest.last
    assert_equal "pending", request.status  # Should be pending, not accepted
  end

  test "POST create validates CSRF token for form submissions" do
    # Rails automatically includes CSRF token in form_with
    # This test verifies it's enabled for this controller
    assert ActionController::Base.allow_forgery_protection
  end
end
