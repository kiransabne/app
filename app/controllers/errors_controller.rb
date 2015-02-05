class ErrorsController < ActionController::Base
  def not_found
    format.html do
      render status: :not_found, layout: "error"
    end
    format.json do
      render json: { code: "not_found", message: "Not Found" }, status: :not_found
    end
  end

  def server_error
    respond_to do |format|
      format.html do
        @without_links = true
        render status: 500, layout: "error"
      end
      format.json do
        render json: { code: "server_error", message: "Server Error" }, status: 500
      end
    end
  end
end
