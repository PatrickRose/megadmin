# frozen_string_literal: true

# Model the other models inherit from
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
