# frozen_string_literal: true

# Controller for file downloads
class DownloadController < ApplicationController
  include CastList

  def show
    player = EventSignup.find(params[:id])
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
    cast_temp.write(pdf_cast_list('event_signups/player_cast_list', player.event))
    cast_temp.close

    begin
      # Initialise the tempfile as .zip
      Zip::OutputStream.open(temp)
      # Add files to the .zip file
      Zip::File.open(temp.path, Zip::File::CREATE) do |zip|
        # Role brief
        if !player.role.nil? && player.role.brief.attached?
          name = team_name + "role brief#{player.role.brief.filename.extension_with_delimiter}"
          zip.add(name, ActiveStorage::Blob.service.path_for(player.role.brief.key))
        end
        # Team brief
        if !player.team.nil? && player.team.brief.attached?
          name = team_name + "team brief#{player.team.brief.filename.extension_with_delimiter}"
          zip.add(name, ActiveStorage::Blob.service.path_for(player.team.brief.key))
        end
        # Rulebook
        if player.event.rulebook.attached?
          name = team_name + "rulebook#{player.event.rulebook.filename.extension_with_delimiter}"
          zip.add(name, ActiveStorage::Blob.service.path_for(player.event.rulebook.key))
        end
        # Additional documents
        player.event.additional_documents.each do |doc|
          zip.add(team_name + doc.filename.to_s, ActiveStorage::Blob.service.path_for(doc.key))
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
