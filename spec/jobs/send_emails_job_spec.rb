# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendEmailsJob do
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
    login_as @organiser
  end

  specify 'the job correctly sends the emails' do
    signup_string = [@signup.to_global_id.to_s]
    event_string = @event.to_global_id.to_s
    organiser_string = @organiser.to_global_id.to_s

    described_class.perform_now(signup_string, event_string, '', organiser_string)

    expect(ActionMailer::Base.deliveries.first.To.value).to eq(@signup.email)
    expect(ActionMailer::Base.deliveries.first.From.value).to eq('no-reply@megadmin.patrickrosemusic.co.uk')
    expect(ActionMailer::Base.deliveries.first.Subject.value).to eq('My Event - Pennine Megagames. Event information!')
  end
end
