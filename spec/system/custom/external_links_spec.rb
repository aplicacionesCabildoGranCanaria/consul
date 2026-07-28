require "rails_helper"

describe "Warning for external links" do
  let(:external_url) { "https://example.com/external-link-test" }

  def add_external_link
    page.execute_script(<<~JS)
      const link = document.createElement("a");

      link.id = "external-link-test";
      link.href = "#{external_url}";
      link.textContent = "External test link";
      link.style.display = "inline-block";
      link.style.visibility = "visible";

      document.body.appendChild(link);
    JS
  end

  def click_external_link
    find("#external-link-test", visible: true).click
  end

  context "when the feature is enabled" do
    before { Setting["feature.gdpr.warning_for_external_links"] = true }

    scenario "warns before leaving to an external website" do
      visit root_path
      add_external_link

      accept_confirm("By confirming, you agree to leave the website.") do
        click_external_link
      end

      expect(page).to have_current_path(external_url)
    end

    scenario "cancels navigation when the user dismisses the confirm dialog" do
      visit root_path
      add_external_link

      dismiss_confirm do
        click_external_link
      end

      expect(page).to have_current_path(root_path)
    end

    scenario "does not warn when using the CKEditor link button", :admin do
      visit new_admin_site_customization_page_path
      fill_in_ckeditor "Content", with: "Filling in to make sure CKEditor is loaded"

      find(".cke_button__link").click

      expect(page).to have_css ".cke_dialog"

      find(".cke_dialog_close_button").click

      expect(page).not_to have_css ".cke_dialog"
      expect(page).to have_current_path(new_admin_site_customization_page_path)
    end
  end

  scenario "does not warn when the feature is disabled" do
    Setting["feature.gdpr.warning_for_external_links"] = nil

    visit root_path
    add_external_link
    click_external_link

    expect(page).to have_current_path(external_url)
  end
end
