require "spec_helper"

describe BulletinsController, type: :controller do
  render_views

  fixtures :trackers

  it "should #index" do
    get :index, {project_id: 1}
    expect(response).to be_success
    expect(assigns(:bulletins)).to_not be_nil
  end


end
