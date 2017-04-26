require 'open-uri'
class ImageProcessorWorker
  include Sidekiq::Worker
  sidekiq_options queue: "image-processor-q"

  def perform(image_id)
    # return if test env
    return if Rails.env.test?

    begin
      # find the image object from id
      image_obj = Image.find(image_id)

      #  Open the image from s3
      url_img = open(URI.encode(image_obj.original_url))

      # Create a new image object
      image = Magick::ImageList.new
      image.from_blob(url_img.read)

      # helper to get the final image url
      # this will generate a random name for the resized image
      final_image_name = image_location(image.format)

      # temp_file_path to save the resized image
      temp_file_path = "#{Rails.root}/tmp/#{final_image_name}"

      # get the size of the image
      img_size = [image[0].columns, image[0].rows]

      # get all possible image sizes
      images_sizes = get_image_sizes()

      # maintaining aspect ratio adjust size to it
      images_sizes.each do |size|
        if img_size[0] > img_size[1]
          dimensions = [size[1],(size[1] * img_size[1]/img_size[0])]
        else
          dimensions = [(size[2]*img_size[0]/img_size[1]),size[2]]
        end
        resized_image = image.resize(dimensions[0],dimensions[1])
        resized_image = resized_image.strip!
        resized_image.write(temp_file_path)
      end

      # upload resized file as public acl and image content type
      acl = 'public-read'

      Rails.logger.info "ImageThumbnailJob URL -before save"

      p final_image_name
      S3_BUCKET.object(final_image_name).upload_file(temp_file_path, acl: acl,
                                                        content_type: 'image', cache_control: 'max-age=31536000')

      Rails.logger.info "ImageThumbnailJob URL: - Upload done"

      final_url = "host_url"+final_image_name

      image_obj.update_attributes(:short_url => final_url , :status => 1)

      Rails.logger.info "DB Update Successful"

      # Delete tmp file from server after processing
      File.delete(temp_file_path)
    rescue
      image_obj.update_attributes(:short_url => nil , :status => 0)
      if Pathname.new(temp_file_path).file?
        File.delete(temp_file_path)
      end
      Rails.logger.info "Some Problem with Job execution"
    end

  end

  private

  # get random name for new compressed image
  def image_location format
    file_name = SecureRandom.uuid+"."+"#{format.downcase}"
    folder = get_folder_name()+file_name
  end

  # get size for new compressed image
  def get_image_sizes
    image_sizes = [["thumb",640,480]]
  end

  # make folder name as date
  def get_folder_name
    if Rails.env.development? || Rails.env.test?
      folder = ""
    else
      folder = "processed/#{Time.now.strftime("%m-%d-%Y")}/"
    end
  end

end
