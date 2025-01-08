require "test_helper"

class Admin::DoctorsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get admin_doctors_new_url
    assert_response :success
  end

  test "should get create" do
    get admin_doctors_create_url
    assert_response :success
  end

  test "should get index" do
    get admin_doctors_index_url
    assert_response :success
  end

  test "should get edit" do
    get admin_doctors_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_doctors_update_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_doctors_destroy_url
    assert_response :success
  end
end
