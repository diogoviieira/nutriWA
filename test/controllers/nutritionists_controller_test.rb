require "test_helper"

class NutritionistsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @nutritionist = Nutritionist.create!(
      name: "Maria Silva",
      location: "Braga"
    )
    @nutritionist.services.create!(name: "Nutritional Plan", price: 50)
  end

  test "index renders successfully" do
    get nutritionists_path
    assert_response :success
  end

  test "index defaults to Braga location when none provided" do
    get nutritionists_path
    assert_response :success
    assert_select ".search-form" # Form should be present
  end

  test "index filters by location parameter" do
    get nutritionists_path, params: { location: "Porto" }
    assert_response :success
  end

  test "index filters by query parameter" do
    get nutritionists_path, params: { query: "Maria" }
    assert_response :success
  end

  test "index filters by both query and location" do
    get nutritionists_path, params: { query: "Nutritional", location: "Braga" }
    assert_response :success
  end

  test "index handles unknown location gracefully" do
    get nutritionists_path, params: { location: "UnknownCity" }
    assert_response :success
  end

  test "requests page renders successfully" do
    get requests_nutritionist_path(@nutritionist)
    assert_response :success
  end

  test "requests page shows nutritionist info" do
    get requests_nutritionist_path(@nutritionist)
    assert_response :success
    assert_match @nutritionist.name, response.body
  end
end
