json.extract! image, :id, :name, :original_url, :short_url, :status, :created_at, :updated_at
json.url image_url(image, format: :json)
