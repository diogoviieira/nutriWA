module Api
  # SECURITY NOTE: This API endpoint has NO authentication/authorization.
  # In production, add authentication (e.g., Devise) and verify:
  #   - Only authenticated nutritionists can access their own requests
  #   - Consider using token-based auth (JWT) instead of null_session
  # Current setup allows ANYONE to accept/reject ANY nutritionist's requests.
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
    rescue ActiveRecord::RecordNotUnique
      render json: { error: "This time slot has already been accepted." }, status: :conflict
    rescue AppointmentRequest::InvalidTransitionError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def reject
      @request.reject!
      render json: request_json(@request)
    rescue AppointmentRequest::InvalidTransitionError => e
      render json: { error: e.message }, status: :unprocessable_entity
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
