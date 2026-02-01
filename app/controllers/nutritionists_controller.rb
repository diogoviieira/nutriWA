class NutritionistsController < ApplicationController
  def index
    @location = params[:location].presence || "Braga"
    @query = params[:query]

    @nutritionists = Nutritionist.search(@query, @location)
                                  .includes(:services)
                                  .page(params[:page])
  end

  def show
    @nutritionist = Nutritionist.find(params[:id])
  end

  def requests
    @nutritionist = Nutritionist.find(params[:id])
  end
end
