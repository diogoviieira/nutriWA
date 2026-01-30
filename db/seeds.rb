# Seeds for NutriWA - Appointment Requests Challenge
# Run with: bin/rails db:seed

puts "🌱 Seeding database..."

# Clean existing data (idempotent)
AppointmentRequest.destroy_all
Service.destroy_all
Nutritionist.destroy_all

# Create Nutritionists with varied locations
nutritionists_data = [
  {
    name: "Maria Silva",
    location: "Braga",
    avatar_url: "https://i.pravatar.cc/150?img=1"
  },
  {
    name: "João Santos",
    location: "Porto",
    avatar_url: "https://i.pravatar.cc/150?img=2"
  },
  {
    name: "Ana Costa",
    location: "Lisboa",
    avatar_url: nil # Test without avatar
  },
  {
    name: "Pedro Oliveira",
    location: "Braga",
    avatar_url: "https://i.pravatar.cc/150?img=3"
  },
  {
    name: "Carla Mendes",
    location: "Coimbra",
    avatar_url: nil
  },
  {
    name: "Rita Ferreira",
    location: "Porto",
    avatar_url: "https://i.pravatar.cc/150?img=4"
  }
]

nutritionists = nutritionists_data.map do |data|
  Nutritionist.create!(data)
end

puts "✅ Created #{nutritionists.count} nutritionists"

# Create Services with varied names and prices
services_templates = [
  { name: "Online Follow-up", price_range: 25..35 },
  { name: "First Appointment", price_range: 40..60 },
  { name: "Nutritional Plan", price_range: 50..80 },
  { name: "Weight Management", price_range: 45..65 },
  { name: "Sports Nutrition", price_range: 55..75 }
]

services_count = 0
nutritionists.each do |nutritionist|
  # Each nutritionist gets 2-3 random services
  services_templates.sample(rand(2..3)).each do |template|
    Service.create!(
      nutritionist: nutritionist,
      name: template[:name],
      price: rand(template[:price_range])
    )
    services_count += 1
  end
end

puts "✅ Created #{services_count} services"

# Create some sample appointment requests (for testing nutritionist view)
sample_requests = [
  {
    nutritionist: nutritionists.first,
    guest_name: "Carlos Rodrigues",
    guest_email: "carlos@example.com",
    requested_at: 3.days.from_now.change(hour: 10, min: 0),
    status: :pending
  },
  {
    nutritionist: nutritionists.first,
    guest_name: "Sofia Alves",
    guest_email: "sofia@example.com",
    requested_at: 5.days.from_now.change(hour: 14, min: 30),
    status: :pending
  },
  {
    nutritionist: nutritionists.second,
    guest_name: "Miguel Pereira",
    guest_email: "miguel@example.com",
    requested_at: 4.days.from_now.change(hour: 11, min: 0),
    status: :pending
  }
]

sample_requests.each do |request_data|
  AppointmentRequest.create!(request_data)
end

puts "✅ Created #{sample_requests.count} sample appointment requests"

puts "\n🎉 Seeding complete!"
puts "\n📊 Summary:"
puts "  - Nutritionists: #{Nutritionist.count}"
puts "  - Services: #{Service.count}"
puts "  - Appointment Requests: #{AppointmentRequest.count}"
puts "\n🔍 Test search with locations: Braga, Porto, Lisboa, Coimbra"
puts "🔍 Test search with services: 'Online Follow-up', 'First Appointment', etc."
