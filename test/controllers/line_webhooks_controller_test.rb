require "test_helper"

class LineWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get line_webhooks_create_url
    assert_response :success
  end
end
