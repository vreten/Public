require 'test_helper'

class SolicitationsControllerTest < ActionController::TestCase
  setup do
    @solicitation = solicitations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:solicitations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create solicitation" do
    assert_difference('Solicitation.count') do
      post :create, solicitation: { bid_delivery_days: @solicitation.bid_delivery_days, buy_num: @solicitation.buy_num, buyer: @solicitation.buyer, category: @solicitation.category, delivery: @solicitation.delivery, end_time: @solicitation.end_time, fbo_solicitation: @solicitation.fbo_solicitation, location: @solicitation.location, naics: @solicitation.naics, recovery_act: @solicitation.recovery_act, removed_at: @solicitation.removed_at, repost_reason: @solicitation.repost_reason, rev: @solicitation.rev, revised_at: @solicitation.revised_at, set_aside_req: @solicitation.set_aside_req, solicitation_num: @solicitation.solicitation_num, subcategory: @solicitation.subcategory, title: @solicitation.title }
    end

    assert_redirected_to solicitation_path(assigns(:solicitation))
  end

  test "should show solicitation" do
    get :show, id: @solicitation
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @solicitation
    assert_response :success
  end

  test "should update solicitation" do
    patch :update, id: @solicitation, solicitation: { bid_delivery_days: @solicitation.bid_delivery_days, buy_num: @solicitation.buy_num, buyer: @solicitation.buyer, category: @solicitation.category, delivery: @solicitation.delivery, end_time: @solicitation.end_time, fbo_solicitation: @solicitation.fbo_solicitation, location: @solicitation.location, naics: @solicitation.naics, recovery_act: @solicitation.recovery_act, removed_at: @solicitation.removed_at, repost_reason: @solicitation.repost_reason, rev: @solicitation.rev, revised_at: @solicitation.revised_at, set_aside_req: @solicitation.set_aside_req, solicitation_num: @solicitation.solicitation_num, subcategory: @solicitation.subcategory, title: @solicitation.title }
    assert_redirected_to solicitation_path(assigns(:solicitation))
  end

  test "should destroy solicitation" do
    assert_difference('Solicitation.count', -1) do
      delete :destroy, id: @solicitation
    end

    assert_redirected_to solicitations_path
  end
end
