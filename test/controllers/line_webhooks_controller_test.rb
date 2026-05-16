require "test_helper"

class LineWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "should receive webhook" do
    post line_webhook_url
    assert_response :success
  end
end
