# frozen_string_literal: true

require 'csv'

# Controller for event signups pages
class EventSignupsController < ApplicationController
  before_action :authenticate_organiser!
  load_and_authorize_resource

  def index
    @event = Event.find(params.expect(:event_id))

    @ct = OrganiserToEvent.find_by(organiser_id: current_organiser.id, event_id: @event.id)
    @control_team = @ct.read_only

    raise CanCan::AccessDenied.new('Not authorized to access this page', :read, EventSignup) if @ct.nil?
    raise CanCan::AccessDenied.new('Not authorized to access this page', :read, EventSignup) unless can? :read, @event

    # Eager-load the team and role the index table links to, avoiding an N+1
    # across signups. The brief-email checklist loads its own associations
    # separately (see Event#checklist_signups).
    @event_signups = EventSignup.where({ event_id: @event.id })
                                .includes(:team, :role)
  end

  def new
    @event_signup = EventSignup.new
    @event = Event.find(params.expect(:event_id))
    @teams = @event.teams.map { |team| [team.name, team.id] }
    @roles = @event.roles.map { |role| [role.name, role.id] }
  end

  def edit
    @event_signup = EventSignup.find(params.expect(:id))
    @event = Event.find(params.expect(:event_id))
    @teams = @event.teams.map { |team| [team.name, team.id] }
    @roles = @event.roles.map do |role|
      ["#{role.name} (Team '#{role.team.name}')", role.id]
    end
  end

  def create
    team = Team.find_by(id: event_signup_params[:team_id], event_id: params[:event_id])
    role = Role.find_by(id: event_signup_params[:role_id], event_id: params[:event_id])

    # A player can be created without a team or role and assigned later; the
    # send-email checklist flags anyone still unassigned. Only reject a genuine
    # mismatch where the chosen role belongs to a different team.
    if team && role && team.roles.exclude?(role)
      redirect_to event_event_signups_path(event_id: params[:event_id]), notice: 'Invalid combination of team and role'
      return
    end

    @event_signup = EventSignup.new(event_signup_params)
    @event_signup.team = team
    @event_signup.role = role
    @event_signup.event_id = params[:event_id]
    @event_signup.uuid = SecureRandom.uuid

    if @event_signup.save
      redirect_to event_event_signups_path(event_id: params[:event_id]), notice: 'Player was successfully created.',
                                                                         status: :see_other
    else
      flash[:alert] = @event_signup.errors.full_messages.to_sentence
      @teams = Team.where(event_id: params[:event_id]).map { |t| [t.name, t.id] }
      @roles = Role.where(event_id: params[:event_id]).map { |r| [r.name, r.id] }
      render :new, status: :unprocessable_content
    end
  end

  def update
    @event_signup = EventSignup.find(params.expect(:id))

    if @event_signup.update(event_signup_params)
      redirect_to event_event_signups_path(event_id: params[:event_id]), notice: 'Player was successfully updated.',
                                                                         status: :see_other
    else
      flash[:alert] = @event_signup.errors.full_messages.to_sentence
      @event = Event.find(params.expect(:event_id))
      @teams = Team.where(event_id: params[:event_id]).map { |team| [team.name, team.id] }
      @roles = Role.where(event_id: params[:event_id]).map { |role| [role.name, role.id] }
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    event_signup = EventSignup.find(params.expect(:id))

    event_signup.destroy

    redirect_to event_event_signups_path(id: event_signup.event_id), notice: 'Player was successfully deleted.',
                                                                     status: :see_other
  end

  # Generates a template CSV file containing all currently unassigned roles for an event
  def generate_template
    # Find all role_ids which are currently in use by event_signups
    assigned_role_ids = EventSignup.where(event_id: params[:event_id])
                                   .where.not(role_id: nil)
                                   .pluck(:role_id)

    # Find all roles which are not included in the previous search
    # I.e. roles which are not in use by event_signups
    unassigned_roles = Role.where(event_id: params[:event_id]).where.not(id: assigned_role_ids)

    # Append each row to a csv file
    csv_file = CSV.generate(headers: true) do |csv|
      csv << %w[name email team role]

      unassigned_roles.each do |role|
        csv << [nil, nil, role.team.name, role.name]
      end
    end

    # Send the csv file
    event = Event.find(params.expect(:event_id))
    send_data csv_file, filename: "Generated Template CSV for #{event.formatted_name}.csv", type: 'text/csv'
  end

  # Uploads players to an event from a csv
  def player_csv
    event_id = params[:event_id]
    event = Event.find(event_id)

    # Check that the organiser has manage access
    raise CanCan::AccessDenied.new('Not authorized to access this page', :read, EventSignup) unless can? :manage, event

    csv_file = params[:player_csv]

    if csv_file.blank?
      redirect_to event_event_signups_path(event_id: event_id),
                  alert: 'Unable to upload players. No file / an incorrect file type has been provided. ' \
                         'Please upload a \'.csv\' file.',
                  status: :see_other
      return
    end

    create_new_teams = params[:create_new_teams] == '1'
    create_new_roles = params[:create_new_roles] == '1'

    # It is not possible to create roles without also creating teams
    if create_new_roles && !create_new_teams
      redirect_to event_event_signups_path(event_id: event_id),
                  alert: 'Unable to upload players. Cannot create roles without also creating teams.',
                  status: :see_other
      return
    end

    csv_text = csv_file.read

    rows = CSV.parse(csv_text, headers: true)
    num_rows = rows.length

    # Removed nil occurrences from array
    headers = rows.headers.compact
    permitted_headers = %w[name email role team]
    forbidden_headers = headers - permitted_headers

    # Do not allow headers except ones listed above
    unless forbidden_headers.empty?
      formatted_headers = forbidden_headers.map { |header| "'#{header}'" }.join(', ')
      redirect_to event_event_signups_path(event_id: event_id),
                  alert: 'CSV upload error. ' \
                         "The uploaded CSV contains the following forbidden header(s): #{formatted_headers}. " \
                         "Please only provide the 'name', 'email', 'team' and 'role' column headers.",
                  status: :see_other
      return
    end

    # Do not allow partial headers, all headers listed above must be present
    not_present_headers = permitted_headers - headers
    unless not_present_headers.empty?
      formatted_headers = not_present_headers.map { |header| "'#{header}'" }.join(', ')
      redirect_to event_event_signups_path(event_id: event_id),
                  alert: 'CSV upload error. ' \
                         "The uploaded CSV does not contain the following header(s): #{formatted_headers}. " \
                         "Please provide the 'name', 'email', 'team' and 'role' column headers.",
                  status: :see_other
      return
    end

    num_new_teams = 0
    num_new_roles = 0

    missing_teams_and_roles = {}

    # Do not save any event signups until we are sure all of them are valid
    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, i|
        row = row.to_h
        row.compact!

        line_number = i + 2

        # Do not allow rows without all fields
        raise "Malformed row on line #{line_number}, not enough fields (#{row.length}, should be 4)" if row.length < 4

        name = row['name']
        email = row['email']
        team = row['team']
        role = row['role']

        # Do not allow malformed emails
        event_signup = EventSignup.new(name: name, email: email)
        unless URI::MailTo::EMAIL_REGEXP.match?(email)
          raise "Malformed row on line #{line_number}, the email '#{email}' is invalid"
        end

        event_signup.event_id = event_id
        event_signup.uuid = SecureRandom.uuid

        event_signup.team = Team.find_by(name: team, event_id: event_id)

        if event_signup.team.nil?
          if create_new_teams
            num_new_teams += 1
            event_signup.team = Team.new(name: team, event_id: event_id)
          else
            # If the team was missing from the database and was not created, tell the user.
            missing_teams_and_roles[team] ||= []
          end
        end

        event_signup.role = Role.find_by(name: role, team: event_signup.team, event_id: event_id)

        if event_signup.role.nil?
          if create_new_roles
            num_new_roles += 1
            event_signup.role = Role.new(name: role, event_id: event_id, team: event_signup.team)
          else
            missing_teams_and_roles[team] = [] unless missing_teams_and_roles.key?(team)
            missing_teams_and_roles[team] << role
          end
        end

        raise event_signup.errors.full_messages.join("\n").to_s unless event_signup.save
      end
    end

    flash[:missing_teams_and_roles] = missing_teams_and_roles
    notice = "#{num_rows} player(s) were uploaded successfully. #{num_new_teams} new team(s) were created. " \
             "#{num_new_roles} new role(s) were created."

    redirect_to event_event_signups_path(event_id: event_id),
                notice: notice, status: :see_other
  rescue StandardError => e
    # Handle access denied
    raise e if e.is_a?(CanCan::AccessDenied)

    # Handle other exception
    redirect_to event_event_signups_path(event_id: event_id), alert: "CSV upload error. #{e.message}",
                                                              status: :see_other
  end

  include CastList

  def organiser_cast_list
    @event = Event.find_by(id: params[:event_id])

    if @event.nil?
      redirect_to '/', alert: "The provided event (#{params[:event_id]}) does not exist.", status: :see_other
      return
    end

    download_organiser_cast_list(@event)
  end

  # Sends emails to all signups
  def email
    event = Event.find(params.expect(:event_id))
    signups = EventSignup.where(event_id: event.id)
    email_note = params[:email_note]
    organiser = Organiser.find_by(id: event.organiser_id)

    # Cannot email if event is a draft
    if event.draft
      redirect_to event_event_signups_path(event_id: event.id), alert: 'Event needs to be published to send emails'
      return
    end

    # Checks all signups have a role and therefore a team
    signups.each do |i|
      if i.role.nil?
        redirect_to event_event_signups_path(event_id: event.id), alert: 'a signup is missing a role'
        return
      end
    end

    if signups.none?
      redirect_to event_event_signups_path(event_id: event.id), alert: 'There are no signups to email'
      return
    end

    # Default to only players who haven't been emailed yet, so re-triggering a
    # send after adding players doesn't re-email everyone. Ticking "resend to all"
    # emails every player regardless.
    recipients = params[:resend_all] == '1' ? signups : signups.where(brief_emailed_at: nil)

    if recipients.none?
      redirect_to event_event_signups_path(event_id: event.id),
                  alert: 'All players have already been emailed. Tick "Resend to players ' \
                         'who have already been emailed" to send to them again.'
      return
    end

    # Refresh the cached player cast list now the roster is being communicated,
    # so every player downloads the current version without re-rendering it.
    regenerate_player_cast_list!(event)

    # Enqueue one throttled job per recipient. A single big job that looped over
    # every signup would, on any failure, be retried from the top by Delayed Job
    # and re-send to everyone already emailed. Per-recipient jobs isolate retries
    # to the recipient that actually failed, and batching stays under the email
    # provider's per-window recipient limit.
    SendBriefEmailJob.enqueue_all(recipients, event, email_note, organiser)

    redirect_to event_event_signups_path(event_id: event.id), notice: 'Emails sent'
  end

  # Sends an email to a single signup
  def email_single
    event = Event.find(params.expect(:event_id))
    organiser = Organiser.find_by(id: event.organiser_id)
    signup = EventSignup.find(params.expect(:id))
    email_note = params[:email_note]

    # Emails cannot be sent for a draft event
    if event.draft
      redirect_to event_event_signups_path(event_id: event.id), alert: 'Event needs to be published to send emails'
      return
    end

    # Makes sure that the signup has a role and therefore a team
    if signup.role.nil?
      redirect_to edit_event_event_signup_path(event_id: event.id, id: signup.id),
                  alert: "this signup doesn't have a role assigned"
      return
    end

    # Make sure a cached cast list exists for the player to download, without
    # forcing a re-render on every individual email.
    player_cast_list_pdf_bytes(event)

    SendBriefEmailJob.perform_later(signup, event, email_note, organiser)

    redirect_to edit_event_event_signup_path(event_id: event.id, id: signup.id), notice: 'Email sent'
  end

  # Re-renders and caches the player cast list PDF on the event.
  def regenerate_cast_list
    event = Event.find(params.expect(:event_id))
    regenerate_player_cast_list!(event)

    redirect_to event_event_signups_path(event_id: event.id), notice: 'Cast list regenerated'
  end

  private

  def event_signup_params
    params.expect(event_signup: %i[name email event_id team_id role_id])
  end
end
