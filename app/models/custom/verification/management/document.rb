load Rails.root.join("app", "models", "verification", "management", "document.rb")

class Verification::Management::Document

  def in_census?
    response = RedSara::RedSaraServiceCaller.new.call(
        document_type, document_number, date_of_birth, postal_code
    )
    response.valid? && valid_age?(response)
  end

end
