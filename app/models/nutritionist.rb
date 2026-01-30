class Nutritionist < ApplicationRecord
  has_many :services, dependent: :destroy
  has_many :appointment_requests, dependent: :destroy

  validates :name, presence: true
  validates :location, presence: true

  # Simple search by name, service name, or location
  scope :search, ->(query, location = nil) {
    results = left_joins(:services).distinct

    if query.present?
      results = results.where(
        "nutritionists.name ILIKE :q OR services.name ILIKE :q",
        q: "%#{query}%"
      )
    end

    if location.present?
      # Order by matching location first, then by name
      results = results.select("nutritionists.*, CASE WHEN nutritionists.location ILIKE #{connection.quote("%#{location}%")} THEN 0 ELSE 1 END as location_priority")
                       .order("location_priority, nutritionists.name")
    else
      results = results.order(:name)
    end

    results
  }
end
