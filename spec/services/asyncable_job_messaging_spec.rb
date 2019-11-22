# frozen_string_literal: true

require "support/database_cleaner"

describe AsyncableJobMessaging, :postgres do
  describe "#add_job_note" do
    let(:owner) { create(:default_user) }
    let(:job) { create(:higher_level_review, intake: create(:intake, user: owner)) }
    let(:user) { User.authenticate!(roles: ["Admin Intake"]) }
    let(:text) { "contents of a new job note" }
    let(:messaging) { AsyncableJobMessaging.new(job: job, current_user: user) }

    subject { messaging.add_job_note(text: text, send_to_intake_user: send_to_intake_user) }

    context "when send_to_intake_user is set" do
      let(:send_to_intake_user) { true }

      it "sends a message to the job owner" do
        message_count = owner.messages.count
        subject
        expect(owner.messages.count).to eq message_count + 1
        expect(owner.messages.last.text).to match("A new note has been added to your HigherLevelReview job")
        expect(owner.messages.last.text).to match(job.path)
        expect(owner.messages.last.message_type).to eq "job_note_added"
      end
    end

    context "when send_to_intake_user isn't set" do
      let(:send_to_intake_user) { false }

      it "doesn't send any note to job owner" do
        message_count = owner.messages.count
        subject
        expect(owner.messages.count).to eq message_count
      end
    end
  end

  describe "#handle_job_failure" do
    let(:owner) { create(:default_user) }
    let!(:job) do
      create(:higher_level_review,
             :requires_processing,
             intake: create(:intake, user: owner),
             establishment_error: "ErrorName followed by more details")
    end
    let(:messaging) { AsyncableJobMessaging.new(job: job) }

    subject { messaging.handle_job_failure }

    context "when a failure happens within 24 hours" do
      it "doesn't send a message to the job owner" do
        message_count = owner.messages.count
        subject
        expect(owner.messages.count).to eq message_count
      end
    end

    context "when a failure first happens after 24 hours" do
      it "sends a message to the job owner" do
        message_count = owner.messages.count
        Timecop.travel(Time.zone.now.tomorrow) do
          subject
        end
        expect(owner.messages.count).to eq message_count + 1
        expect(owner.messages.last.text).to match("unable to complete because of an error")
        expect(owner.messages.last.text).to match(job.path)
        expect(owner.messages.last.text).not_to match("more details")
        expect(owner.messages.last.message_type).to eq "job_failing"
      end
    end

    context "when multiple failures happen after 24 hours" do
      it "sends only one message to the job owner" do
        message_count = owner.messages.count
        Timecop.travel(Time.zone.now.tomorrow) do
          3.times { messaging.handle_job_failure }
        end
        expect(owner.messages.count).to eq message_count + 1
      end
    end
  end
end