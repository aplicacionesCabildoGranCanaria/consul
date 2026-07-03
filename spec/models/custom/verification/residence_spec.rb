require "rails_helper"

describe Verification::Residence do
  let!(:geozone) { create(:geozone, census_code: "01") }

  let(:residence) do
    build(
      :verification_residence,
      document_number: "12345678Z",
      postal_code: "35001"
    )
  end

  def mock_red_sara_for(record, valid: true, postal_code: nil, date_of_birth: nil)
    census_data = double(
      valid?: valid,
      postal_code: postal_code || record.postal_code,
      date_of_birth: date_of_birth || record.date_of_birth,
      district_code: "01",
      gender: "male"
    )

    allow_any_instance_of(RedSara::RedSaraServiceCaller)
      .to receive(:call)
      .and_return(census_data)

    census_data
  end

  describe "validations" do
    before do
      mock_red_sara_for(residence)
    end

    it "is valid" do
      expect(residence).to be_valid
    end

    describe "dates" do
      it "is valid with a valid date of birth" do
        residence = build(:verification_residence, date_of_birth: "1947-09-12", postal_code: "35001")
        mock_red_sara_for(residence)

        residence.valid?

        expect(residence.errors[:date_of_birth]).to be_empty
      end

      it "is not valid without a date of birth" do
        residence = build(:verification_residence, date_of_birth: "", postal_code: "35001")
        mock_red_sara_for(residence)

        expect(residence).not_to be_valid
        expect(residence.errors[:date_of_birth]).to include("can't be blank")
      end
    end

    it "validates user has allowed age" do
      residence = build(:verification_residence, date_of_birth: 5.years.ago.to_date, postal_code: "35001")
      mock_red_sara_for(residence)

      expect(residence).not_to be_valid
      expect(residence.errors[:date_of_birth]).to include("You don't have the required age to participate")
    end

    it "validates uniquness of document_number" do
      user = create(:user)
      residence.user = user
 
      mock_red_sara_for(residence)
      residence.save!

      another_residence = build(
        :verification_residence,
        document_number: "12345678Z",
        postal_code: "35001"
      )

      mock_red_sara_for(another_residence)

      another_residence.valid?

      expect(another_residence.errors[:document_number]).to include("has already been taken")
    end

    it "validates census terms" do
      residence.terms_of_service = nil

      expect(residence).not_to be_valid
    end

    describe "postal code" do
      before do
        mock_red_sara_for(residence)
      end

      it "is not valid when it's nil" do
        residence.postal_code = nil

        expect(residence).not_to be_valid
      end

      it "is valid when postal code starts with 35" do
        residence.postal_code = "35001"
        mock_red_sara_for(residence)
        expect(residence).to be_valid

        residence.postal_code = "35100"
        mock_red_sara_for(residence)
        expect(residence).to be_valid

        residence.postal_code = "35999"
        mock_red_sara_for(residence)
        expect(residence).to be_valid
      end

      it "is not valid when postal code does not start with 35" do
        residence.postal_code = "28013"

        expect(residence).not_to be_valid
        expect(residence.errors[:postal_code]).to include(
          I18n.t("verification.residence.new.error_not_allowed_postal_code")
        )
      end

      it "does not accept codes that contain 35 but do not start with 35" do
        residence.postal_code = "00350"

        expect(residence).not_to be_valid
      end
    end
  end

  describe "new" do
    it "upcases document number" do
      residence = Verification::Residence.new(document_number: "x1234567z")

      expect(residence.document_number).to eq("X1234567Z")
    end

    it "removes all characters except numbers and letters" do
      residence = Verification::Residence.new(document_number: " 12.345.678 - B")

      expect(residence.document_number).to eq("12345678B")
    end
  end

  describe "save" do
    it "stores document number, document type, geozone, date of birth, gender and verification dates" do
      user = create(:user)
      residence.user = user

      mock_red_sara_for(residence)

      residence.save!

      user.reload

      expect(user.document_number).to eq("12345678Z")
      expect(user.document_type).to eq("1")
      expect(user.date_of_birth.year).to eq(1980)
      expect(user.date_of_birth.month).to eq(12)
      expect(user.date_of_birth.day).to eq(31)
      expect(user.gender).to eq("male")
      expect(user.geozone).to eq(geozone)
      expect(user.postal_code).to eq("35001")
      expect(user.residence_verified_at).to be_present
      expect(user.level_two_verified_at).to be_present
      expect(user.verified_at).to be_present
    end
  end

  describe "tries" do
    it "increases tries after a failed call to RedSara" do
      mock_red_sara_for(residence, valid: false)

      residence.valid?

      expect(residence.user.lock.tries).to eq(1)
    end

    it "does not increase tries after a validation error" do
      residence.postal_code = ""

      residence.valid?

      expect(residence.user.lock).to be nil
    end
  end

  describe "Failed census call" do
    it "stores failed census API calls" do
      residence = build(
        :verification_residence,
        document_number: "12345678Z",
        postal_code: "35001"
      )

      mock_red_sara_for(residence, valid: false)

      residence.save

      expect(FailedCensusCall.count).to eq(1)
      expect(FailedCensusCall.first).to have_attributes(
        user_id: residence.user.id,
        document_number: "12345678Z",
        document_type: "1",
        date_of_birth: Date.new(1980, 12, 31),
        postal_code: "35001"
      )
    end
  end
end