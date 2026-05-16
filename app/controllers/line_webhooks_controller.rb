class LineWebhooksController < ApplicationController
  skip_before_action :verify_authemticity_token

  def create
    head :ok
  end
end
