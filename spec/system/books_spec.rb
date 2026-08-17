require "rails_helper"

RSpec.describe "Users", type: :system do
  it "shows books on root path" do
    visit root_path
    expect(page).to have_content("Libros")
  end
end
