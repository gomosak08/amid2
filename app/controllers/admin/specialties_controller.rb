class Admin::SpecialtiesController < ApplicationController
  before_action :set_specialty, only: %i[ show edit update destroy ]

  # GET /admin/specialties or /admin/specialties.json
  def index
    @specialties = Specialty.all
  end

  # GET /admin/specialties/1 or /admin/specialties/1.json
  def show
  end

  # GET /admin/specialties/new
  def new
    @specialty = Specialty.new
  end

  # GET /admin/specialties/1/edit
  def edit
  end

  # POST /admin/specialties or /admin/specialties.json
  def create
    @specialty = Specialty.new(specialty_params)

    respond_to do |format|
      if @specialty.save
        format.html { redirect_to [:admin, @specialty], notice: "Specialty was successfully created." }
        format.json { render :show, status: :created, location: @specialty }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @specialty.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/specialties/1 or /admin/specialties/1.json
  def update
    respond_to do |format|
      if @specialty.update(specialty_params)
        format.html { redirect_to [:admin, @specialty], notice: "Specialty was successfully updated." }
        format.json { render :show, status: :ok, location: @specialty }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @specialty.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/specialties/1 or /admin/specialties/1.json
  def destroy
    @specialty.destroy!

    respond_to do |format|
      format.html { redirect_to admin_specialties_path, status: :see_other, notice: "Specialty was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_specialty
      @specialty = Specialty.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def specialty_params
      params.require(:specialty).permit(:name)
    end
end
