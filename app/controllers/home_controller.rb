class HomeController < ApplicationController
  def show
    index = Rails.root.join("public/frontend/index.html")

    if index.file?
      render file: index.to_s, layout: false
    else
      render plain: "Build the frontend with npm --prefix frontend run build, or open the Vite development server at http://localhost:5173.", status: :service_unavailable
    end
  end
end
