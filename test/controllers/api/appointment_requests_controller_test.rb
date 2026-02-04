require "test_helper"

module Api
  class AppointmentRequestsControllerTest < ActionDispatch::IntegrationTest
    def setup
      @nutritionist = Nutritionist.create!(
        name: "Maria Silva",
        location: "Braga"
      )

      @pending_request = AppointmentRequest.create!(
        nutritionist: @nutritionist,
        guest_name: "Carlos Rodrigues",
        guest_email: "carlos@example.com",
        requested_at: 2.days.from_now
      )
    end

    test "index returns pending requests as JSON" do
      get api_nutritionist_appointment_requests_path(@nutritionist)

      assert_response :success
      json = JSON.parse(response.body)
      assert_kind_of Array, json
      assert_equal 1, json.length
      assert_equal @pending_request.guest_name, json.first["guest_name"]
    end

    test "index only returns pending requests" do
      # Create accepted request
      accepted = AppointmentRequest.create!(
        nutritionist: @nutritionist,
        guest_name: "Ana Costa",
        guest_email: "ana@example.com",
        requested_at: 3.days.from_now
      )
      accepted.update_column(:status, 1) # accepted

      get api_nutritionist_appointment_requests_path(@nutritionist)

      json = JSON.parse(response.body)
      assert_equal 1, json.length
      assert_equal @pending_request.id, json.first["id"]
    end

    test "accept changes status to accepted" do
      patch accept_api_nutritionist_appointment_request_path(@nutritionist, @pending_request)

      assert_response :success
      assert_equal "accepted", @pending_request.reload.status
    end

    test "accept returns updated request as JSON" do
      patch accept_api_nutritionist_appointment_request_path(@nutritionist, @pending_request)

      json = JSON.parse(response.body)
      assert_equal "accepted", json["status"]
    end

    test "accept on non-pending request returns error" do
      @pending_request.update_column(:status, 2) # rejected

      patch accept_api_nutritionist_appointment_request_path(@nutritionist, @pending_request)

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert json["error"].present?
    end

    test "reject changes status to rejected" do
      patch reject_api_nutritionist_appointment_request_path(@nutritionist, @pending_request)

      assert_response :success
      assert_equal "rejected", @pending_request.reload.status
    end

    test "reject returns updated request as JSON" do
      patch reject_api_nutritionist_appointment_request_path(@nutritionist, @pending_request)

      json = JSON.parse(response.body)
      assert_equal "rejected", json["status"]
    end

    test "reject on non-pending request returns error" do
      @pending_request.update_column(:status, 1) # accepted

      patch reject_api_nutritionist_appointment_request_path(@nutritionist, @pending_request)

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert json["error"].present?
    end

    test "accept cancels conflicting requests for same slot" do
      same_slot = @pending_request.requested_at

      conflicting = AppointmentRequest.create!(
        nutritionist: @nutritionist,
        guest_name: "Sofia Alves",
        guest_email: "sofia@example.com",
        requested_at: same_slot
      )

      patch accept_api_nutritionist_appointment_request_path(@nutritionist, @pending_request)

      assert_equal "accepted", @pending_request.reload.status
      assert_equal "cancelled", conflicting.reload.status
    end
  end
end
