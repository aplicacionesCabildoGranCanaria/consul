require "rails_helper"

describe "User verification" do
  scenario "Verification with residency" do
    create(:geozone)
    user = create(:user)

    login_as(user)

    visit account_path
    click_link "Verify my account"

    verify_residence

    expect(page).not_to have_link "Verify my account"
    expect(page).to have_content "Account verified"
  end
end