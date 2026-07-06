# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendBriefEmailJob do
  before do
    @organiser = create(:organiser)
    @event = create(:event, organiser_id: @organiser.id)
    @organiser_to_event = create(:organiser_to_event,
                                 event_id: @event.id,
                                 organiser_id: @organiser.id)
    @team = create(:team, event: @event)
    @role = create(:role, event: @event, name: 'role', team: @team)
    @signup = create(:event_signup, event: @event,
                                    name: 'signup 1',
                                    email: 'email1@email.com',
                                    role: @role,
                                    team: @team)
  end

  specify 'the job sends the brief email to the signup' do
    described_class.perform_now(@signup, @event, '', @organiser)

    expect(ActionMailer::Base.deliveries.first.To.value).to eq(@signup.email)
    expect(ActionMailer::Base.deliveries.first.From.value).to eq('no-reply@megadmin.patrickrosemusic.co.uk')
    expect(ActionMailer::Base.deliveries.first.Subject.value).to eq('My Event - Pennine Megagames. Event information!')
  end

  specify 'the job records when the brief was emailed' do
    expect { described_class.perform_now(@signup, @event, '', @organiser) }
      .to(change { @signup.reload.brief_emailed_at }.from(nil))
  end

  specify 'a rate-limited send retries the recipient instead of failing' do
    ActiveJob::Base.queue_adapter = :test
    mail = instance_double(ActionMailer::MessageDelivery)
    allow(SignupMailer).to receive(:brief_email).and_return(mail)
    allow(mail).to receive(:deliver_now).and_raise(Net::SMTPServerBusy, '421 recipient limit exceeded')

    expect { described_class.perform_now(@signup, @event, '', @organiser) }
      .to have_enqueued_job(described_class)

    expect(@signup.reload.brief_emailed_at).to be_nil
  end

  describe '.enqueue_all' do
    specify 'spreads later batches out to respect the provider rate limit' do
      ActiveJob::Base.queue_adapter = :test
      allow(described_class).to receive(:batch_size).and_return(1)

      role2 = create(:role, event: @event, name: 'role 2', team: @team)
      second = create(:event_signup, event: @event, name: 'signup 2',
                                     email: 'email2@email.com', role: role2, team: @team)

      described_class.enqueue_all([@signup, second], @event, '', @organiser)

      jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
      expect(jobs.length).to eq(2)
      # First batch goes out now; the second batch is delayed by batch_interval.
      expect(jobs.last[:at]).to be_within(5).of(described_class.batch_interval.from_now.to_f)
    end
  end
end
