class AppointmentRequestsController < ApplicationController
  def create
    @nutritionist = Nutritionist.find(params[:nutritionist_id])
    @appointment_request = @nutritionist.appointment_requests.build(appointment_request_params)

    if @appointment_request.save
      redirect_to root_path, notice: "Appointment request sent successfully!"
    else
      redirect_to root_path, alert: @appointment_request.errors.full_messages.join(", ")
    end
  end

  private

  def appointment_request_params
    params.require(:appointment_request).permit(:guest_name, :guest_email, :requested_at)
  end
end
