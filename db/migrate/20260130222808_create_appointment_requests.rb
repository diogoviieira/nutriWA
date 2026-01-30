class CreateAppointmentRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :appointment_requests do |t|
      t.string :guest_name, null: false
      t.string :guest_email, null: false
      t.datetime :requested_at, null: false
      t.integer :status, null: false, default: 0
      t.references :nutritionist, null: false, foreign_key: true

      t.timestamps
    end

    add_index :appointment_requests, :guest_email
    add_index :appointment_requests, :status
    add_index :appointment_requests, [:nutritionist_id, :requested_at, :status], name: "idx_requests_on_nutritionist_slot_status"
  end
end
