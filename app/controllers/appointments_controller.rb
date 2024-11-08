# app/controllers/appointments_controller.rb
class AppointmentsController < ApplicationController


  def new
    #puts "Params: #{params.inspect}" # Check incoming params
    #puts "esos eran los params"
  
    # Load package and doctor information based on passed parameters
    @package = Package.find(params[:package_id])
    @duration = @package.duration 
    @doctors = Doctor.all
    @doctor_id = params[:doctor_id]
    @start_date = params[:start_date]
    
    if @doctor_id && @start_date
      @doctor = Doctor.find(@doctor_id)
      @available_times = fetch_available_times(@doctor, @start_date)
    else
      @available_times = []
    end
  
    # Initialize new appointment instance for form binding
    @appointment = Appointment.new

  end
    



  def create

    
    @doctors = Doctor.all
    @package = Package.find(params[:appointment][:package_id])
    start_date = Time.zone.parse(params[:appointment][:start_date])
    duration_minutes = @package.duration
    end_date = start_date + duration_minutes.to_i.minutes
    doctor_id = appointment_params[:doctor_id]
  
    # Verify reCAPTCHA before proceeding with the booking
    if verify_recaptcha(model: @appointment) # `verify_recaptcha` automatically validates the reCAPTCHA response
      if time_slot_available?(doctor_id, start_date)
        status = "Scheduled"
        @appointment = Appointment.new(appointment_params.merge(end_date: end_date, status: status))
  
        if @appointment.save
          if AppointmentMailer.appointment_confirmation(@appointment).deliver_later
            Rails.logger.info "Confirmation email enqueued for #{@appointment.email}"
            flash[:notice] = 'Email sent successfully.'
          else
            flash[:alert] = 'Failed to send email. Please try again.'
          end

          redirect_to @appointment, notice: 'Appointment was successfully created.'
        else
          render :new
        end
      else
        # If the time slot is taken, re-render the `new` view with an error
        flash.now[:alert] = "The selected time is no longer available. Please choose a different time."
        @available_times = fetch_available_times(Doctor.find(doctor_id), start_date.to_date)
        render :new
      end
    else
      # If reCAPTCHA validation fails, add a flash message to prompt the user
      flash.now[:alert] = "Please complete the CAPTCHA to confirm you are human."
      # Preserve available times and doctors list, and re-render the form with all filled data intact
      @available_times = fetch_available_times(Doctor.find(doctor_id), start_date.to_date)
      render :new
    end
  end

  def show
    @appointment = Appointment.find(params[:id])
  end

  private

  def appointment_params
    params.require(:appointment).permit(:name, :age, :email, :phone, :sex, :doctor_id, :package_id, :status, :duration, :start_date)
  end

  def time_slot_available?(doctor_id, start_date)
    Appointment.where(doctor_id: doctor_id, start_date: start_date).empty?
  end


  def fetch_available_times(doctor, selected_date)
    # Ensure `selected_date` is parsed as a Date object
    selected_date = Date.parse(selected_date) if selected_date.is_a?(String)
    
    # Retrieve all available time slots for the doctor on the selected day
    day_name = selected_date.strftime("%A") # e.g., "Monday"
    available_times = []
  
    if doctor.available_hours && doctor.available_hours[day_name]
      doctor.available_hours[day_name].each do |range|
        start_time, end_time = range.split('-')
        start_time = Time.zone.parse("#{selected_date} #{start_time}")
        end_time = Time.zone.parse("#{selected_date} #{end_time}")
  
        # Generate 30-minute slots within the available range
        while start_time < end_time
          available_times << start_time
          start_time += 30.minutes
        end
      end
    end
  
    # Fetch booked appointment times for the doctor on the selected date
    booked_times = Appointment.where(doctor_id: doctor.id, start_date: selected_date.all_day).pluck(:start_date)
  
    # Filter out any available times that overlap with booked appointments
    available_times.reject { |time| booked_times.include?(time) }
  end

end
