require "rails_helper"

RSpec.describe "Home page", type: :system do
  it "renders the built React page served by Rails" do
    driven_by :selenium, using: :headless_chrome do |options|
      options.binary = ENV.fetch("CHROME_BIN") if ENV["CHROME_BIN"].present?

      if ENV["CI"] == "true"
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
      end
    end

    visit root_path

    expect(page).to have_css("#app h1", text: "ACME CompScope")
  end
end
