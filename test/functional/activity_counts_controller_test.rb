require 'test_helper'

class ActivityCountsControllerTest < ActionController::TestCase
  setup do
    @activity_count = activity_counts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:activity_counts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create activity_count" do
    assert_difference('ActivityCount.count') do
      post :create, activity_count: {  }
    end

    assert_redirected_to activity_count_path(assigns(:activity_count))
  end

  test "should show activity_count" do
    get :show, id: @activity_count
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @activity_count
    assert_response :success
  end

  test "should update activity_count" do
    put :update, id: @activity_count, activity_count: {  }
    assert_redirected_to activity_count_path(assigns(:activity_count))
  end

  test "should destroy activity_count" do
    assert_difference('ActivityCount.count', -1) do
      delete :destroy, id: @activity_count
    end

    assert_redirected_to activity_counts_path
  end
end
