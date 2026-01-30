class CreateNutritionists < ActiveRecord::Migration[7.2]
  def change
    create_table :nutritionists do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.string :avatar_url

      t.timestamps
    end
  end
end
