class Nutritionist < ApplicationRecord
  has_many :services, dependent: :destroy
  has_many :appointment_requests, dependent: :destroy

  validates :name, presence: true
  validates :location, presence: true

  # Approximate coordinates for Portuguese cities (lat, lon)
  CITY_COORDINATES = {
    "braga" => [ 41.55, -8.42 ],
    "porto" => [ 41.15, -8.61 ],
    "lisboa" => [ 38.72, -9.14 ],
    "coimbra" => [ 40.21, -8.43 ],
    "faro" => [ 37.02, -7.93 ],
    "aveiro" => [ 40.64, -8.65 ],
    "viseu" => [ 40.66, -7.91 ],
    "leiria" => [ 39.74, -8.81 ],
    "setubal" => [ 38.52, -8.89 ],
    "evora" => [ 38.57, -7.91 ],
    "braganca" => [ 41.81, -6.76 ],
    "bragança" => [ 41.81, -6.76 ],
    "guimaraes" => [ 41.44, -8.29 ],
    "guimarães" => [ 41.44, -8.29 ],
    "viana do castelo" => [ 41.69, -8.83 ],
    "vila real" => [ 41.30, -7.74 ],
    "castelo branco" => [ 39.82, -7.49 ],
    "santarem" => [ 39.24, -8.69 ],
    "santarém" => [ 39.24, -8.69 ],
    "portalegre" => [ 39.29, -7.43 ],
    "beja" => [ 38.01, -7.86 ]
  }.freeze

  # Simple search by name, service name, or location
  scope :search, ->(query, location = nil) {
    results = left_joins(:services).distinct

    if query.present?
      sanitized_query = "%#{sanitize_sql_like(query)}%"
      results = results.where(
        "nutritionists.name ILIKE :q OR services.name ILIKE :q",
        q: sanitized_query
      )
    end

    if location.present?
      search_coords = CITY_COORDINATES[location.downcase.strip]

      if search_coords
        # Calculate distance using Euclidean approximation (good enough for Portugal)
        distance_sql = CITY_COORDINATES.map do |city, coords|
          lat, lon = coords
          "WHEN LOWER(nutritionists.location) = '#{city}' THEN #{euclidean_distance(search_coords, coords)}"
        end.join(" ")

        results = results.select("nutritionists.*, CASE #{distance_sql} ELSE 9999 END as distance")
                         .order("distance, nutritionists.name")
      else
        # Unknown location: exact match first, then alphabetical
        sanitized_location = "%#{sanitize_sql_like(location)}%"
        results = results.select("nutritionists.*, CASE WHEN nutritionists.location ILIKE #{connection.quote(sanitized_location)} THEN 0 ELSE 1 END as location_priority")
                         .order("location_priority, nutritionists.name")
      end
    else
      results = results.order(:name)
    end

    results
  }

  def self.euclidean_distance(coord1, coord2)
    lat1, lon1 = coord1
    lat2, lon2 = coord2
    Math.sqrt((lat1 - lat2)**2 + (lon1 - lon2)**2).round(4)
  end
end
