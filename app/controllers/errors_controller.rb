# frozen_string_literal: true

# Controller for error pages
class ErrorsController < ApplicationController
  def not_found
    render_error(404, 'The requested page was not found')
  end

  def internal_server_error
    render_error(500, 'Internal server error')
  end

  def unprocessable_content
    render_error(422, 'Unprocessable content')
  end

  private

  def render_error(code, message)
    @error_code = code
    @error_message = message

    respond_to do |format|
      format.html { render template: 'layouts/errors', layout: false, status: code }
      format.json { render json: { error: message }, status: code }
      format.any  { head code }
    end
  end
end
