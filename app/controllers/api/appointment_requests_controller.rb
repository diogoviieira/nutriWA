module Api
  class AppointmentRequestsController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :set_nutritionist
    before_action :set_request, only: [ :accept, :reject ]

    def index
      @requests = @nutritionist.appointment_requests.pending.order(requested_at: :asc)
      render json: @requests.map { |r| request_json(r) }
    end

    def accept
      @request.accept!
      render json: request_json(@request)
    end

    def reject
      @request.reject!
      render json: request_json(@request)
    end

    private

    def set_nutritionist
      @nutritionist = Nutritionist.find(params[:nutritionist_id])
    end

    def set_request
      @request = @nutritionist.appointment_requests.find(params[:id])
    end

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
