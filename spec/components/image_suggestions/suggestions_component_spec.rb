require "rails_helper"

describe ImageSuggestions::SuggestionsComponent do
  let(:component) { ImageSuggestions::SuggestionsComponent.new(llm_response) }
  let(:llm_response) { double(results: results, errors: []) }
  let(:results) { double(photos: [photo]) }
  let(:photo) { double(id: "1", src: { "small" => "https://example.com/image1.jpg" }, user: user) }
  let(:user) { double(name: "Photographer 1") }

  describe "#suggested_images" do
    it "returns photos from results" do
      expect(component.suggested_images).to eq [photo]
    end

    context "when response results are blank" do
      let(:llm_response) { double(results: nil, errors: []) }

      it "returns an empty array" do
        expect(component.suggested_images).to eq []
      end
    end
  end

  describe "#has_errors?" do
    context "when response has no errors" do
      it "returns false" do
        expect(component.has_errors?).to be false
      end
    end

    context "when response has errors" do
      let(:llm_response) { double(results: [], errors: ["Error message"]) }

      it "returns true" do
        expect(component.has_errors?).to be true
      end
    end
  end

  describe "#error_messages" do
    context "when response has errors" do
      let(:llm_response) { double(results: [], errors: ["Error 1", "Error 2"]) }

      it "returns the errors array" do
        expect(component.error_messages).to eq ["Error 1", "Error 2"]
      end
    end

    context "when response has no errors" do
      it "returns empty array" do
        expect(component.error_messages).to eq []
      end
    end
  end

  describe "rendering" do
    context "when there are no results and no errors" do
      let(:llm_response) { double(results: [], errors: []) }

      it "shows the suggest button and the no images found message" do
        render_inline component

        expect(page).to have_content "Suggest an image with AI"
        expect(page).to have_content "No suggestions could be found."
      end
    end

    context "when there are errors" do
      let(:llm_response) { double(results: [], errors: ["Test error"]) }

      it "renders error message" do
        render_inline component

        expect(page).to have_content "Test error"
        expect(page).to have_css "small.error"
      end
    end

    context "when there are suggested images" do
      it "renders the grid with attach buttons" do
        render_inline component

        expect(page).to have_css ".js-attach-suggested-image", count: 1
        expect(page).to have_css "#suggested-image-1"
        expect(page).to have_css ".suggested-image-button"
      end

      it "includes accessibility attributes for container, buttons and images" do
        render_inline component

        expect(page).to have_css ".suggested-images-container[role='region'][aria-label='Suggested images']"
        expect(page).to have_css ".js-attach-suggested-image[aria-label='Attach suggested image 1 of 1']"
        expect(page).to have_css "img.suggested-image[alt='Photographer 1']"
        expect(page).to have_css "[aria-describedby='suggested-image-desc-1']"
        expect(page).to have_css "#suggested-image-desc-1"
      end
    end
  end
end
