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
end
