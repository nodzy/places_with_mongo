require 'test_helper'

class PlsControllerTest < ActionController::TestCase
  setup do
    @pl = pls(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:pls)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create pl" do
    assert_difference('Pl.count') do
      post :create, pl: { formatted_address: @pl.formatted_address }
    end

    assert_redirected_to pl_path(assigns(:pl))
  end

  test "should show pl" do
    get :show, id: @pl
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @pl
    assert_response :success
  end

  test "should update pl" do
    patch :update, id: @pl, pl: { formatted_address: @pl.formatted_address }
    assert_redirected_to pl_path(assigns(:pl))
  end

  test "should destroy pl" do
    assert_difference('Pl.count', -1) do
      delete :destroy, id: @pl
    end

    assert_redirected_to pls_path
  end
end
