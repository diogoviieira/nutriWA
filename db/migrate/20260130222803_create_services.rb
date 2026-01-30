class CreateServices < ActiveRecord::Migration[7.2]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.references :nutritionist, null: false, foreign_key: true

      t.timestamps
    end
  end
end
