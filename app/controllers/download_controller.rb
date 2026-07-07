# frozen_string_literal: true

# Controller for file downloads
class DownloadController < ApplicationController
  include CastList

  def show
    player = EventSignup.find(params.expect(:id))
    team_name = if player.team.nil? || player.team.name.blank?
                  ''
                else
                  "team #{player.team.name} "
                end

    # Create zip tempfile
    zip_filename = "#{"#{player.event.name} #{team_name}"}.zip"
    temp = Tempfile.new(zip_filename)

    # Create cast list tempfile
    cast_temp = Tempfile.new("#{team_name}castlist.pdf")
    cast_temp.binmode
    cast_temp.write(player_cast_list_pdf_bytes(player.event))
    cast_temp.close

    begin
      # Initialise the tempfile as .zip
      Zip::OutputStream.open(temp)
      # Add files to the .zip file
      Zip::File.open(temp.path, create: true) do |zip|
        # Role brief
        if !player.role.nil? && player.role.brief.attached?
          name = team_name + "role brief#{player.role.brief.filename.extension_with_delimiter}"
          zip.get_output_stream(name) { |entry| entry.write(player.role.brief.download) }
        end
        # Team brief
        if !player.team.nil? && player.team.brief.attached?
          name = team_name + "team brief#{player.team.brief.filename.extension_with_delimiter}"
          zip.get_output_stream(name) { |entry| entry.write(player.team.brief.download) }
        end
        # Rulebook
        if player.event.rulebook.attached?
          name = team_name + "rulebook#{player.event.rulebook.filename.extension_with_delimiter}"
          zip.get_output_stream(name) { |entry| entry.write(player.event.rulebook.download) }
        end
        # Additional documents
        player.event.additional_documents.each do |doc|
          zip.get_output_stream(team_name + doc.filename.to_s) { |entry| entry.write(doc.download) }
        end
        # Cast list
        zip.add("#{team_name}cast.pdf", File.join(cast_temp.path))
      end
      # Send the data from the tempfile to the user
      data = File.read(temp.path)
      send_data(data, type: 'application/zip', filename: zip_filename)
    ensure
      # Delete the tempfiles
      temp.close
      temp.unlink
      cast_temp.unlink
    end
  end
end
