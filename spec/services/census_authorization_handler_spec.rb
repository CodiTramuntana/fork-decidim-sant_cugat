# frozen_string_literal: true
require "rails_helper"
require "decidim/dev/test/authorization_shared_examples"

describe CensusAuthorizationHandler do
  let(:subject) { handler }
  let(:handler) { described_class.from_params(params) }
  let(:date_of_birth) { Date.civil(1987, 9, 17) }
  let(:document_number) { "12345678A" }
  let(:params) do
    {
      date_of_birth: date_of_birth,
      document_number: document_number
    }
  end

  it_behaves_like "an authorization handler"

  context "when user is too young" do
    let(:date_of_birth) { 15.years.ago.to_date }

    before do
      allow(handler)
        .to receive(:response)
              .and_return(JSON.parse("{ \"res\": 1 }"))
    end

    it { is_expected.not_to be_valid }

    it "has an error in the date of birth" do
      subject.valid?
      expect(subject.errors[:date_of_birth]).to be_present
    end
  end

  context "with a valid response" do
    before do
      allow(handler)
        .to receive(:response)
        .and_return(JSON.parse("{ \"res\": 1 }"))
    end

    describe "document_number" do
      context "when it isn't present" do
        let(:document_number) { nil }

        it { is_expected.not_to be_valid }
      end

      context "with an invalid format" do
        let(:document_number) { "(╯°□°）╯︵ ┻━┻" }

        it { is_expected.not_to be_valid }
      end
    end

    describe "date_of_birth" do
      context "when it isn't present" do
        let(:date_of_birth) { nil }

        it { is_expected.not_to be_valid }
      end
    end

    context "when everything is fine" do
      it { is_expected.to be_valid }
    end
  end

  context "unique_id" do
    it "generates a different ID for a different document number" do
      handler.document_number = "ABC123"
      unique_id1 = handler.unique_id

      handler.document_number = "XYZ456"
      unique_id2 = handler.unique_id

      expect(unique_id1).to_not eq(unique_id2)
    end

    it "generates the same ID for the same document number" do
      handler.document_number = "ABC123"
      unique_id1 = handler.unique_id

      handler.document_number = "ABC123"
      unique_id2 = handler.unique_id

      expect(unique_id1).to eq(unique_id2)
    end

    it "hashes the document number" do
      handler.document_number = "ABC123"
      unique_id = handler.unique_id

      expect(unique_id).to_not include(handler.document_number)
    end
  end

  context "with an invalid response" do
    context "with an invalid response code" do
      before do
        allow(handler)
          .to receive(:response)
          .and_return(JSON.parse("{ \"res\": 2}"))
      end

      it { is_expected.to_not be_valid }
    end
  end
end
