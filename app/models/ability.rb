# frozen_string_literal: true

# Defines page authorisation
class Ability
  include CanCan::Ability

  def initialize(organiser, params)
    return if organiser.blank?

    # Allow organisers to manage their events
    can :manage, Event do |event|
      OrganiserToEvent.exists?(event_id: event.id, organiser_id: organiser.id, read_only: false)
    end

    # Allow organisers to add new signups to their events
    can [:create, :player_csv, :generate_template, :organiser_cast_list, :email, :email_single], EventSignup do
      # Check if the user can manage the Event associated with the EventSignup
      event = Event.find(params[:event_id])
      can?(:manage, event)
    end

    can :manage, Event, organiser_id: organiser.id
    can :read, Event, organiser_to_events: { organiser_id: organiser.id }

    # Allow organisers to edit signups for their events
    can %i[read update destroy], EventSignup,
        event_id: OrganiserToEvent.where(organiser_id: organiser.id, read_only: false).pluck(:event_id)

    # Allow organisers to manage teams and roles for their events
    can [:manage], [Team, Role],
        event_id: OrganiserToEvent.where(organiser_id: organiser.id, read_only: false).pluck(:event_id)

    # Allow organisers to create teams and roles for their events
    can [:new, :create], [Team, Role] do
      event = Event.find(params[:event_id])
      can?(:manage, event)
    end

    # Allow organisers to create events
    can %i[new create], Event

    # Control ------

    # Allow control team to view their events
    can :read, Event do |event|
      OrganiserToEvent.exists?(event_id: event.id, organiser_id: organiser.id, read_only: true)
    end

    # Allow control team to view their event signups
    can [:read], EventSignup,
        event_id: OrganiserToEvent.where(organiser_id: organiser.id, read_only: true).pluck(:event_id)

    can [:read], [Team, Role],
        event_id: OrganiserToEvent.where(organiser_id: organiser.id, read_only: true).pluck(:event_id)

    # Define abilities for the user here. For example:
    #
    #   return unless user.present?
    #   can :read, :all
    #   return unless user.admin?
    #   can :manage, :all
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, published: true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md
  end
end
