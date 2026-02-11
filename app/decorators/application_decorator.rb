# frozen_string_literal: true

# Base draper decorator class
class ApplicationDecorator < Draper::Decorator
  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end
end
