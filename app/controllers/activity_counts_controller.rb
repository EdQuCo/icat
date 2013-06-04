class ActivityCountsController < ApplicationController
  # GET /activity_counts
  # GET /activity_counts.json
  #def index
  #  @activity_counts = ActivityCount.all
  #
  #  respond_to do |format|
  #    format.html # index.html.erb
  #    format.json { render json: @activity_counts }
  #  end
  #end

  # GET /activity_counts/1
  # GET /activity_counts/1.json
  #def show
  #  @activity_count = ActivityCount.find(params[:id])
  #
  #  respond_to do |format|
  #    format.html # show.html.erb
  #    format.json { render json: @activity_count }
  #  end
  #end

  # GET /activity_counts/new
  # GET /activity_counts/new.json
  #def new
  #  @activity_count = ActivityCount.new
  #
  #  respond_to do |format|
  #    format.html # new.html.erb
  #    format.json { render json: @activity_count }
  #  end
  #end

  # GET /activity_counts/1/edit
  def edit
    @activity_count = ActivityCount.find(params[:id])
  end

  # POST /activity_counts
  # POST /activity_counts.json
  def create
    # The JSON file can contain lots of records to insert
    user = User.find_by_username(params[:username])

    if user.nil?
      user = User.create!(params[:username])
    end

    #render :text => response_body

    #puts 'WHAT!!'

    created = []
    json = JSON.parse(params[:counts])
    count_array = json.fetch('activity_counts')
    count_array.each do |node|
      puts params[:counts].to_s

      # Create Activity Count object
      # :date, :counts, :epoch, :charging
      activity_count = user.activity_counts.new(
          :date => node['date'],
          :counts => node['counts'],
          :epoch => node['epoch'],
          :charging => node['charging'])

      if activity_count.save
        created << [params[:username], node['date'], node['counts'], node['epoch'], node['charging']]
      end
    end

    render :text => created

    #@activity_count = ActivityCount.new(params[:activity_count])
    #
    #respond_to do |format|
    #  if @activity_count.save
    #    format.html { redirect_to @activity_count, notice: 'Activity count was successfully created.' }
    #    format.json { render json: @activity_count, status: :created, location: @activity_count }
    #  else
    #    format.html { render action: 'new' }
    #    format.json { render json: @activity_count.errors, status: :unprocessable_entity }
    #  end
    #end
  end

  # PUT /activity_counts/1
  # PUT /activity_counts/1.json
  def update
    @activity_count = ActivityCount.find(params[:id])

    respond_to do |format|
      if @activity_count.update_attributes(params[:activity_count])
        format.html { redirect_to @activity_count, notice: 'Activity count was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @activity_count.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activity_counts/1
  # DELETE /activity_counts/1.json
  def destroy
    @activity_count = ActivityCount.find(params[:id])
    @activity_count.destroy

    respond_to do |format|
      format.html { redirect_to activity_counts_url }
      format.json { head :no_content }
    end
  end

  # POST /activity_counts/query.json
  def query
    user = User.find_by_username(params[:username])

    if user.nil?
      render :text => 'User not found.'
    else
      json = JSON.parse(params[:bundle])

      # Set date range
      puts params[:bundle]
      puts json['start_date']
      puts json['end_date']

      start_date = DateTime.parse(json['start_date'])
      end_date = DateTime.parse(json['end_date'])
      activity_counts = user.activity_counts.where(:date => start_date..end_date)

      # Empty?

      bout_allowance = json['bout_allowance']
      unless bout_allowance.nil?
        bout_allowance = 2
      end

      bout_size = json['bout_size']
      unless bout_size
        bout_size = 10
      end

      if json.keys.include?('cut-point-ranges')
        ranges = json.fetch('cut-point-ranges')

        # Create the Cut Point ranges
        intensities = []
        min = 0
        ranges.each do |intensity|
          max = intensity['max']
          intensities << Intensity.new(intensity['intensity'], min, max)
          min = intensity['max'] + 1
        end
      end

      total_counts = 0
      total_calories = 0
      off_time = 0
      nonwear_time = 0

      date = start_date

      # iterate through activity counts
      activity_counts.each  do |activity_count|
        off_time += (activity_count.date - date).round / 1.minute
        # ERROR
        date = activity_count.date

        counts = activity_count.counts

        # append total counts
        total_counts += counts

        # classify epoch
        if activity_count.charging
          nonwear_time += 1.minute
        else

        end

        intensities.each do |intensity|
          if intensity.in_range?(counts)
            intensity.add_counts(counts)
            puts "this count: #{activity_count.date} (#{activity_count.counts}) belongs to #{intensity.name}"
            break
          end
        end

        # adjust date
        off_time += (activity_count.date - date).round / 1.minutes

      end


      # iterate through epochs
      #while date <= end_date do
      #  puts date
      #  date += 1.minutes
      #end

      intensities.each do |intensity|
        puts "name: #{intensity.name}, counts: #{intensity.counts}, bouts: #{intensity.bouts}, minutes: #{intensity.time}"
      end

      algorithm = json['calories_algorithm']
      total_calories = Util.compute_calories total_counts, algorithm

      puts total_calories

      #Util.compute_sleep_score activity_counts, start_date, end_date

      render json: {:counts => activity_counts.as_json(:only => [:charging]), :total_counts => total_counts, :total_calories => total_calories, :nonwear_time => nonwear_time, :off_time => off_time}
    end
  end
end
