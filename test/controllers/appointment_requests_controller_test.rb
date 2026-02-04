require "test_helper"

class AppointmentRequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @nutritionist = Nutritionist.create!(
      name: "Maria Silva",
      location: "Braga"
    )
  end

  test "create with valid params redirects with success notice" do
    assert_difference "AppointmentRequest.count", 1 do
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
    assert_match "successfully", response.body
  end

  test "create with invalid email redirects with error" do
    assert_no_difference "AppointmentRequest.count" do
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
  end

  test "create with past date redirects with error" do
    assert_no_difference "AppointmentRequest.count" do
      post appointment_requests_path, params: {
        nutritionist_id: @nutritionist.id,
        appointment_request: {
          guest_name: "John Doe",
          guest_email: "john@example.com",
          requested_at: 1.day.ago
        }
      }
    end

    assert_redirected_to root_path
  end

  test "create handles duplicate pending request gracefully" do
    # Create first request
    AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "John Doe",
      guest_email: "john@example.com",
      requested_at: 2.days.from_now
    )

    # Second request from same email - should cancel first one
    post appointment_requests_path, params: {
      nutritionist_id: @nutritionist.id,
      appointment_request: {
        guest_name: "John Doe",
        guest_email: "john@example.com",
        requested_at: 3.days.from_now
      }
    }

    assert_redirected_to root_path
  end
end
