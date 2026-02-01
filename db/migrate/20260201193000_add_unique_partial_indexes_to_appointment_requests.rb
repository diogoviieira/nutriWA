class AddUniquePartialIndexesToAppointmentRequests < ActiveRecord::Migration[7.2]
  def change
    add_index :appointment_requests,
              :guest_email,
              unique: true,
              where: "status = 0",
              name: "index_appointment_requests_on_guest_email_pending"

    add_index :appointment_requests,
              [ :nutritionist_id, :requested_at ],
              unique: true,
              where: "status = 1",
              name: "index_appointment_requests_on_nutritionist_slot_accepted"
  end
end
