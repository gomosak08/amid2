require "test_helper"

class SurgeriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get surgeries_index_url
    assert_response :success
  end
end
