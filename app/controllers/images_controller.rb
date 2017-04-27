class ImagesController < ApplicationController
  before_action :set_s3_direct_post, only: [:new, :create]
  before_action :authenticate

  # GET /images
  # GET /images.json
  def index
    @images = Image.where(:status => 1 ).order(created_at: :desc).paginate(:page => params[:page], :per_page => 5)
  end

  # GET /images/new
  def new
    @image = Image.new
  end

  # POST /images
  def create
    @image = Image.new(image_params)
    @image.status = 0
    respond_to do |format|
      if @image.save
        ImageProcessorWorker.perform_async(@image.id)
        format.html { redirect_to images_path , notice: 'Image has successfully uploaded.' }
      else
        format.html { render :new }
      end
    end

  end


  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def image_params
      params.require(:image).permit(:name, :original_url)
    end

    # Setting up the presigned URL
    def set_s3_direct_post
      folder = get_folder_name()
      @s3_direct_post = S3_BUCKET.presigned_post(key: "#{folder}/#{SecureRandom.uuid}.${filename}",
                                                    success_action_status: '201',
                                                        acl: 'public-read' )
    end

    def authenticate
      authenticate_or_request_with_http_basic do |username, password|
        username == "admin" && password == "#open-table"
      end
    end

    def get_folder_name
      folder = "uploads/#{Time.now.strftime("%m-%d-%Y")}"
    end


    # def policy
    #   Base64.encode64(policy_data.to_json).gsub("\n", "")
    # end
    #
    # def policy_data
    #   {
    #     expiration: 10.hours.from_now,
    #     conditions: [
    #       ["starts-with", "$utf8", ""],
    #       ["starts-with", "$key", ""],
    #       ["content-length-range", 0, 500.megabytes],
    #       ["Content-Type","image/jpg"],
    #       {bucket: S3_BUCKET},
    #       {acl: "public-read"}
    #     ]
    #   }
    # end
end
