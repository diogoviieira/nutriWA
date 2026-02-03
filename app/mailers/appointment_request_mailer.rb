class AppointmentRequestMailer < ApplicationMailer
  def accepted(appointment_request)
    @appointment_request = appointment_request
    @nutritionist = appointment_request.nutritionist

    mail(
      to: @appointment_request.guest_email,
      subject: "Your appointment request has been accepted!"
    )
  end

  def rejected(appointment_request)
    @appointment_request = appointment_request
    @nutritionist = appointment_request.nutritionist

    mail(
      to: @appointment_request.guest_email,
      subject: "Update on your appointment request"
    )
  end

  def cancelled(appointment_request)
    @appointment_request = appointment_request
    @nutritionist = appointment_request.nutritionist

    mail(
      to: @appointment_request.guest_email,
      subject: "Your appointment request was cancelled"
    )
  end
end
