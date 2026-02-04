require "test_helper"

class ApiAppointmentRequestsTest < ActionDispatch::IntegrationTest
  def setup
    @nutritionist = Nutritionist.create!(
      name: "Test Nutritionist",
      location: "Braga"
    )

    @request1 = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "John Silva",
      guest_email: "john@example.com",
      requested_at: 2.days.from_now.change(hour: 10, min: 0)
    )

    @request2 = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Maria Santos",
      guest_email: "maria@example.com",
      requested_at: 2.days.from_now.change(hour: 14, min: 0)
    )
  end

  test "GET index returns all pending requests for nutritionist" do
    get api_nutritionist_appointment_requests_path(@nutritionist)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json.length
    assert_equal "John Silva", json.first["guest_name"]
    assert_equal "pending", json.first["status"]
  end

  test "GET index orders requests by requested_at ascending" do
    # Create a request with earlier time
    earlier_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Early Bird",
      guest_email: "early@example.com",
      requested_at: 1.day.from_now.change(hour: 9, min: 0)
    )

    get api_nutritionist_appointment_requests_path(@nutritionist)
    json = JSON.parse(response.body)

    assert_equal "Early Bird", json.first["guest_name"]
    assert_equal "John Silva", json.second["guest_name"]
    assert_equal "Maria Santos", json.third["guest_name"]
  end

  test "GET index only returns pending requests" do
    @request1.accept!

    get api_nutritionist_appointment_requests_path(@nutritionist)
    json = JSON.parse(response.body)

    # Should only return request2 (pending)
    assert_equal 1, json.length
    assert_equal "Maria Santos", json.first["guest_name"]
  end

  test "PATCH accept changes status to accepted" do
    assert_enqueued_emails 1 do
      patch accept_api_nutritionist_appointment_request_path(@nutritionist, @request1)
      assert_response :success
    end

    json = JSON.parse(response.body)
    assert_equal "accepted", json["status"]
    assert_equal "accepted", @request1.reload.status
  end

  test "PATCH accept cancels conflicting pending requests" do
    # Create another request for the same slot
    conflicting_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "Conflict Guest",
      guest_email: "conflict@example.com",
      requested_at: @request1.requested_at
    )

    # Accepting request1 should cancel conflicting_request
    assert_enqueued_emails 2 do  # One accepted, one cancelled
      patch accept_api_nutritionist_appointment_request_path(@nutritionist, @request1)
    end

    assert_equal "accepted", @request1.reload.status
    assert_equal "cancelled", conflicting_request.reload.status
  end

  test "PATCH accept on non-pending request returns error" do
    @request1.accept!

    patch accept_api_nutritionist_appointment_request_path(@nutritionist, @request1)
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_match /Can only accept pending requests/, json["error"]
  end

  test "PATCH reject changes status to rejected" do
    assert_enqueued_emails 1 do
      patch reject_api_nutritionist_appointment_request_path(@nutritionist, @request1)
      assert_response :success
    end

    json = JSON.parse(response.body)
    assert_equal "rejected", json["status"]
    assert_equal "rejected", @request1.reload.status
  end

  test "PATCH reject on non-pending request returns error" do
    @request1.reject!

    patch reject_api_nutritionist_appointment_request_path(@nutritionist, @request1)
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_match /Can only reject pending requests/, json["error"]
  end

  test "PATCH accept with invalid nutritionist_id returns not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      patch accept_api_nutritionist_appointment_request_path(99999, @request1)
    end
  end

  test "PATCH accept with invalid request_id returns not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      patch accept_api_nutritionist_appointment_request_path(@nutritionist, 99999)
    end
  end

  # SECURITY NOTE: These tests document the security issue
  # In production, these should return :unauthorized or :forbidden
  test "SECURITY: any user can access any nutritionist panel (no auth)" do
    other_nutritionist = Nutritionist.create!(
      name: "Other Nutritionist",
      location: "Porto"
    )

    # Should be able to access other nutritionist's requests without auth
    get api_nutritionist_appointment_requests_path(other_nutritionist)
    assert_response :success  # Currently succeeds - security issue!

    # In production, this should be:
    # assert_response :unauthorized
  end

  test "SECURITY: any user can accept requests for any nutritionist (no auth)" do
    other_nutritionist = Nutritionist.create!(
      name: "Other Nutritionist",
      location: "Porto"
    )

    other_request = AppointmentRequest.create!(
      nutritionist: other_nutritionist,
      guest_name: "Victim Guest",
      guest_email: "victim@example.com",
      requested_at: 2.days.from_now
    )

    # Should be able to accept other nutritionist's requests without auth
    patch accept_api_nutritionist_appointment_request_path(other_nutritionist, other_request)
    assert_response :success  # Currently succeeds - security issue!

    # In production, this should be:
    # assert_response :unauthorized or :forbidden
  end
end
