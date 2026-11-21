module Api
  module V1
    class AnalyticsController < ActionController::API
      def show
        response.headers["Cache-Control"] = "no-store"
        filters = params.permit(:country, :department)

        render json: CompensationAnalyticsQuery.new(**filters.to_h.symbolize_keys).call
      end
    end
  end
end
