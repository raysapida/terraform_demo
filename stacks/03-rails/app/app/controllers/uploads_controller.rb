class UploadsController < ApplicationController
  def index
    @uploads = Upload.with_attached_file.order(created_at: :desc)
    @upload = Upload.new
    @bucket = ENV["S3_BUCKET"]
    @database = ActiveRecord::Base.connection.select_value("select version()")
  end

  def create
    @upload = Upload.new(file: params.dig(:upload, :file))

    if @upload.save
      redirect_to root_path, notice: "Uploaded #{@upload.file.filename}"
    else
      redirect_to root_path, alert: "Choose a file first"
    end
  end
end
