class ImageSuggestions::SuggestionsComponent < ApplicationComponent
  attr_reader :suggestions

  def initialize(suggestions)
    @suggestions = suggestions
  end

  private

    def suggested_images
      suggestions.results.presence&.photos || []
    end

    def has_errors?
      suggestions.errors.any?
    end

    def error_messages
      suggestions.errors
    end
end
