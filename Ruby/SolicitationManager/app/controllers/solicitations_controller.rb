class SolicitationsController < ApplicationController
  before_action :set_solicitation, only: [:show, :edit, :update, :destroy]

  # GET /solicitations
  # GET /solicitations.json
  def index
    @solicitations = Solicitation.all
  end

  # GET /solicitations/1
  # GET /solicitations/1.json
  def show
  end

  # GET /solicitations/new
  def new
    @solicitation = Solicitation.new
  end

  # GET /solicitations/1/edit
  def edit
  end

  # POST /solicitations
  # POST /solicitations.json
  def create
    @solicitation = Solicitation.new(solicitation_params)

    respond_to do |format|
      if @solicitation.save
        format.html { redirect_to @solicitation, notice: 'Solicitation was successfully created.' }
        format.json { render action: 'show', status: :created, location: @solicitation }
      else
        format.html { render action: 'new' }
        format.json { render json: @solicitation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /solicitations/1
  # PATCH/PUT /solicitations/1.json
  def update
    respond_to do |format|
      if @solicitation.update(solicitation_params)
        format.html { redirect_to @solicitation, notice: 'Solicitation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @solicitation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /solicitations/1
  # DELETE /solicitations/1.json
  def destroy
    @solicitation.destroy
    respond_to do |format|
      format.html { redirect_to solicitations_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_solicitation
      @solicitation = Solicitation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def solicitation_params
      params.require(:solicitation).permit(:buy_num, :rev, :title, :buyer, :end_time, :set_aside_req, :location, :category, :subcategory, :naics, :fbo_solicitation, :recovery_act, :delivery, :bid_delivery_days, :repost_reason, :solicitation_num, :revised_at, :removed_at)
    end
end
