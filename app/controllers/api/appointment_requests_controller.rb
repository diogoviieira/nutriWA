module Api
  class AppointmentRequestsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
      @nutritionist = Nutritionist.find(params[:nutritionist_id])
      @requests = @nutritionist.appointment_requests.pending.order(requested_at: :asc)

      render json: @requests.map { |r| request_json(r) }
    end

    def accept
      @request = AppointmentRequest.find(params[:id])
      @request.accept!

      render json: request_json(@request)
    end

    def reject
      @request = AppointmentRequest.find(params[:id])
      @request.reject!

      render json: request_json(@request)
    end

    private

    def request_json(request)
      {
        id: request.id,
        guest_name: request.guest_name,
        guest_email: request.guest_email,
        requested_at: request.requested_at,
        status: request.status,
        created_at: request.created_at
      }
    end
  end
end
