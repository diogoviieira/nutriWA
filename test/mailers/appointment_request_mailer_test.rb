require "test_helper"

class AppointmentRequestMailerTest < ActionMailer::TestCase
  def setup
    @nutritionist = Nutritionist.create!(
      name: "Dr. Test",
      location: "Lisboa"
    )
    @appointment_request = AppointmentRequest.create!(
      nutritionist: @nutritionist,
      guest_name: "John Silva",
      guest_email: "john@example.com",
      requested_at: 2.days.from_now
    )
  end

  test "accepted email" do
    email = AppointmentRequestMailer.accepted(@appointment_request)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "john@example.com" ], email.to
    assert_equal "Your appointment request has been accepted!", email.subject
    assert_match "John Silva", email.body.encoded
    assert_match "Dr. Test", email.body.encoded
  end

  test "rejected email" do
    email = AppointmentRequestMailer.rejected(@appointment_request)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "john@example.com" ], email.to
    assert_equal "Update on your appointment request", email.subject
    assert_match "John Silva", email.body.encoded
    assert_match "declined", email.body.encoded
  end

  test "cancelled email" do
    email = AppointmentRequestMailer.cancelled(@appointment_request)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "john@example.com" ], email.to
    assert_equal "Your appointment request was cancelled", email.subject
    assert_match "John Silva", email.body.encoded
    assert_match "no longer available", email.body.encoded
  end
end
