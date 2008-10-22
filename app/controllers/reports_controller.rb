class ReportsController < ApplicationController

	before_filter :check_refresh	
	caches_page :cohort, :virtual_art_register, :missed_appointments, :defaulters, 
              :height_weight_by_user, :monthly_drug_quantities, :survival_analysis, :old_cohort
           
	# delete cache report if ?refresh appended to url
	def check_refresh
		expire_page :action => action_name unless params[:refresh].nil? 
	end

  def index
    redirect_to :action => "select"
  end
  # Example report code created with Priscilla
  def height_weight_by_user
    @height_weight_encounters = Hash.new(0)
    EncounterType.find_by_name("Height/Weight").encounters.collect{|e|@height_weight_encounters[e.provider.name] += 1}
  end


  def self.sample_weight_counter
    total = 0
    return Patient.find(:all)[10..20].collect{|patient| 
      weight_observations = patient.observations.find_by_concept_name("Weight")
      unless weight_observations.first.nil?
        weight_observation_date = weight_observations.first.obs_datetime
        total += 1 if weight_observation_date > Date.new(2007,1,1).to_time
        if weight_observation_date > Date.new(2007,1,1).to_time
          weight_observation_date
        else
          "not match #{weight_observations.first.obs_datetime.to_s}"
        end
      end
    }
  end
  
  def select_cohort

    # this action sets up the form that lists all of the available quarters
    # after selecting one it sends it to the cohort action below
  
    #change start date to be the earliest observation in the database (this is on x4k's computer but not in svn)
    #@start_date = Date.new(2003,2,2)
    @start_date = Encounter.find(:first, :order => 'encounter_datetime', :conditions => 'encounter_datetime is not NULL and encounter_datetime <> \'0000-00-00\'').encounter_datetime
    @end_date = Date.today
    if params[:id]
			params[:id] = params[:id].sub(/\s/, "+")
			redirect_to "/reports/cohort/#{params[:id]}" and return 
    end
    render :layout => "application" #this forces the default application layout to be used which gives us the touchscreen toolkit
  end
  
  
#WTK
  def select_encounters_by_providers

	# this action sets up the form that lists all of the available time periods
	# after selecting one it sends it to the encounters by providers action below

	if params[:id]
			params[:id] = params[:id].tr(" ", "+")
			if params[:id] == "Custom+period" then 
				redirect_to "/reports/set_date_range/#{params[:id]}" and return
			else
			redirect_to "/reports/encounters_by_providers/#{params[:id]}" and return 
			end
	end
        render :layout => "application" #this forces the default application layout to be used which gives us the touchscreen toolkit
  end
#WTK 

  def set_cohort_date_range
    if params[:start_year].nil? or params[:end_year].nil?
      @needs_date_picker = true
      day=Array.new(31){|d|d + 1 } 
      unknown=Array.new
      unknown[0]= "Unknown" 
      days_with_unknown = day<< "Unknown"
      @days = [""].concat day

      @monthOptions = "<option>" "" "</option>"
  1.upto(12){ |number| 
       @monthOptions += "<option value = '" + number.to_s + "'>" + Date::MONTHNAMES[number] + "</option>"
      }
      @monthOptions << "<option>" "Unknown" "</option>"

      @min_date = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date 
      render :layout => "application" 
    else
      start_date = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
      end_date = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"
      redirect_to :action => "cohort", :id => params[:id], :start_date => start_date, :end_date => end_date
    end
  end

#WTK    REFACTOR:  This should use a common fonction with the set_cohort_date_range
  def set_date_range
    if params[:start_year].nil? or params[:end_year].nil?
      @needs_date_picker = true
      day=Array.new(31){|d|d + 1 } 

      @days = [""].concat day

      @monthOptions = "<option>" "" "</option>"
  1.upto(12){ |number| 
       @monthOptions += "<option value = '" + number.to_s + "'>" + Date::MONTHNAMES[number] + "</option>"
      }

      @min_date = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date 
      render :layout => "application" 
    else
      start_date = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
      end_date = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"
      redirect_to :action => "encounters_by_providers", :id => params[:id], :start_date => start_date, :end_date => end_date
    end
  end
  #WTK 
#WTK
def encounters_by_providers
	redirect_to :action => 'select_encounters_by_providers' and return if params[:id].nil?
	
	#FIXME: I think that this week and last week has an overlapping boundry problem for midnight on sunday, not a big deal, but should be fixed.
	case params["id"]
		when "Cumulative"
			start_datetime = Encounter.find(:first, :order => 'encounter_datetime', 
										:conditions => 'encounter_datetime is not NULL and encounter_datetime <> \'0000-00-00\'').encounter_datetime
			start_datetime = start_datetime.year.to_s + '-' +start_datetime.month.to_s + '-' +start_datetime.day.to_s + ' 00:00:00'
			end_datetime = Time.now
			end_datetime = time_to_sql_string(end_datetime)
		when "Today"
			start_datetime = Time.today
			start_datetime = time_to_sql_string(start_datetime)
			end_datetime = Time.today+1.day-1.second 	#11:59:59pm, today
			end_datetime = time_to_sql_string(end_datetime)
		when "Last+24+hours"
			start_datetime = Time.now-1.day
			start_datetime = time_to_sql_string(start_datetime)
			end_datetime = Time.now
			end_datetime = time_to_sql_string(end_datetime)
		when "Last+7+days"
			start_datetime = Time.now-7.days
			start_datetime = time_to_sql_string(start_datetime)
			end_datetime = Time.now
			end_datetime = time_to_sql_string(end_datetime)
		when "This+week"
			start_datetime = Time.today
			start_datetime = start_datetime.at_beginning_of_week
			start_datetime = time_to_sql_string(start_datetime)
			end_datetime = Time.today
			end_datetime = time_to_sql_string(end_datetime)
		when "Last+week"
			start_datetime = Time.today - 7.days
			start_datetime = start_datetime.at_beginning_of_week
			start_datetime = time_to_sql_string(start_datetime)
			end_datetime = Time.today - 7.days
			end_datetime =end_datetime.at_beginning_of_week 
			end_datetime =end_datetime +7.days
			end_datetime = time_to_sql_string(end_datetime)
		when "Custom+period"
			# Dates will be made inclusive by serching from midnight on the start date to 23:59:59 on the end date.
			start_datetime = "#{params[:start_date]} 00:00:00"
			end_datetime = "#{params[:end_date]} 23:59:59"

		else
			redirect_to :action => 'select_encounters_by_providers' and return
	end
	# FIXME: user_encounter_crosstab_sql() is much faster than user_encounter_crosstab(), but is not very ruby like.
	@results = user_encounter_crosstab_sql(start_datetime, end_datetime)
	#~ @results = user_encounter_crosstab(start_datetime, end_datetime)

	# Go through the results (each a hash) and add attributes for the username of the provider, the encounter type name, and provider's role
	@results.each_key{|provider_id|
					# get the usernames
					u =  User.find(:first, :conditions => "user_id = '#{provider_id}'")
					if u then 
						@results[provider_id]["username"] = u.username 
					else 
							@results[provider_id]["username"] = "NULL" 
					end
					
					#get the user roles, 
					#FIXME: only looking for first user role, might need to do better
					ri =  UserRole.find(:first, :conditions => "user_id = '#{provider_id}'")  #
					if ri then 
						role = Role.find(:first,:conditions => "role_id =  '#{ri.role_id}'") 
					end
					
					if role then 
						@results[provider_id]["role"] = role.role 
					else 
						@results[provider_id]["role"] = "NULL" 
					end
					
					#~ #get the encounter_types 
					#~ et = EncounterType.find(:first, :conditions => "encounter_type_id = '#{@results[provider_id]['encounter_type']}'")	
					#~ if et then @results[provider_id]["encounter_type_name"] = et.name else @results[provider_id]["encounter_type_name"] = "NULL" end
					
				  }

	
	
	@labels_array = []
	#FIXME : Need to make the encounter type ids for nill and undefined (in the encounter type table) equal to "NULL"
	EncounterType.find(:all).collect {|et|  @labels_array << [ et.name, et.encounter_type_id]}
	#FIXME : Need to make the encounter type ids for nill and undefined (in the encounter type table) equal to "NULL"
	@labels_array << ["NULL",nil]
	
	#Build up an array of all the user names in alphabetical order
	@users_array = [] 
	@results.each_key{|u|  @users_array << [@results[u]["username"], u] }
	@users_array.sort!	
	
	@results_array = []
	#Build up the @results_array array, one user at a time. Each user will get one row in the crosstab table.  Each user results in an array like:
	#[username, role, encounter_type_1_count, encounter_type_2_count, ..., encounter_type_NULL_count, total_encounters_count]
	#FIXME: This is crazy.  There must be some way of converting a hash of hashes (@results) into an array of hashes, and then sorting that array based on one of the hash values.
	#FIXME: But if we do manage that we still need to build up the totals value.  Probably should do that some where else anyway.
	@users_array.collect{|u|
					    temp_user_array = [u[0]] #first item is the username
					    #second item is the role
	   				    temp_user_array << @results[u[1]]['role']
					    
					    temp_count_total = 0
					   @labels_array.collect{|e|  #then we go through all the results and add the counts for all the encounter types, and get total
										x=@results[u[1]][e[1]]
										if x.nil? then x=0 end#will hold number of encounters for this user and encounter type
										
										temp_user_array << x
										temp_count_total += x
										
										
									      }
					   temp_user_array << temp_count_total
					   @results_array << temp_user_array
					   
					   }
	  
	  #prepend Username to the array
	@labels_array = [["Username", "Username"] , ["Role", "Role"]] +@labels_array
	@labels_array << ["Total" , ""]
	
	@end = end_datetime
	@start = start_datetime
	
	#~ #Make a figure
    @image_path = make_scruffy_figure(@results)
	 
end

#this takes an instance of the Ruby Time class and makes it look right for a mysql querry
def time_to_sql_string(time)
	return " #{time.year}-#{time.month}-#{time.day} #{time.hour}:#{time.min}:#{time.sec}"
end
	
	
#Should this  be in the User model?  Creae a hash of hashes: {provider_id => {encounter_type_id => number or encounters, ...}, ...}
def user_encounter_crosstab(start_datetime, end_datetime)
		#This works, but is slow
		results = Hash.new()  # Create a hash to hold our data
		Encounter.find(:all, :conditions => ["encounter_datetime > '#{start_datetime}' and encounter_datetime < '#{end_datetime}'"] ).collect{|en| 
		
				if results[en.provider_id].nil? then#check if provider_id has been seen before
					results[en.provider_id] = Hash.new(0)  #if it hasn't create a new hash
				end
				
				if  results[en.provider_id][en.encounter_type].nil? then #check if provider/encounter has been seen before
					results[en.provider_id][en.encounter_type] = 1 #if not initialize
				else 
					results[en.provider_id][en.encounter_type] += 1  #if so increment
				end
				
########################add totals 
		}
		# this could replace user_encounter_crosstab_sql, and is more ruby, but doesn't work
		# users = Encounter.find(:all, :conditions => ["date_created > '#{start_datetime}' and date_created < '#{end_datetime}'"] ).collect{|en|
			
		#~ #This is not working the way I think it should, it seems to only do one of the groupings
		#~ results = Encounter.count(:all, :group => :provider_id , :group =>:encounter_type, 
			#~ :conditions =>  ["date_created > '#{start_datetime}' and date_created < '#{end_datetime}'"] )
		return results
	
end
#This does not seem like the ruby way of doing it, but its fast and works
def user_encounter_crosstab_sql(start_datetime, end_datetime)
	sql_string = "SELECT e.provider_id, e.encounter_type, count(*) as count FROM encounter e WHERE encounter_datetime > '#{start_datetime}' AND encounter_datetime < '#{end_datetime}' GROUP BY e.provider_id, e.encounter_type "
	results = Encounter.find_by_sql([sql_string])
	#turn the array of objects into a hash of hashes
	results_hash = Hash.new()
	for r in results do
		if results_hash[r.attributes["provider_id"]].nil? then results_hash[r.attributes["provider_id"]] = Hash.new() end
		results_hash[r.attributes["provider_id"]]["provider_id"] = r.attributes["provider_id"].to_i
		results_hash[r.attributes["provider_id"]][r.attributes["encounter_type"]] = r.attributes["count"].to_i
	end
	return results_hash
end
#WTK

#WTK
  def make_scruffy_figure(data, y_axis_label="X", x_axis_label="Y", title="No Title")
	stamp = Time.now.to_i.to_s
    outfile = "/charts/scruffy" + stamp +".png"
	
	#~ graph = Scruffy::Graph.new
	#~ graph.title = title
	#~ graph.renderer = Scruffy::Renderers::Pie.new

	#~ graph.add :pie, '', {
		#~ 'Apple' => 20,
		#~ 'Banana' => 100,
		#~ 'Orange' => 70,
		#~ 'Taco' => 30
	#~ }
	#~ render_path = "./public"+outfile
	#~ graph.render :to => render_path 
	#~ graph.render :width => 300, :height => 200,
		 #~ :to => render_path, :as => 'png'
    
    
    graph = Scruffy::Graph.new
    graph.title = title
    #graph.value_formatter = Scruffy::Formatters::Percentage.new(:precision => 0)
    for u in @results_array do
        graph.add :stacked do |stacked|
                stacked.add :bar, u[0], u[2 .. 5]
        end
    end
    graph.point_markers = @labels_array[2..5]
    render_path = "./public"+outfile
    graph.render :to => "render_path"
    graph.render  :width => 500, :to => render_path, :as => 'png'


	return outfile
   end

#WTK


  def cohort

    redirect_to :action => 'select_cohort' and return if params[:id].nil?
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])  

    @quarter_start = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date if @quarter_start.nil?
		@quarter_end = Date.today if @quarter_end.nil?
  
    PatientAdherenceDate.find(:first)
    PatientPrescriptionTotal.find(:first)
    PatientWholeTabletsRemainingAndBrought.find(:first)
    PatientHistoricalOutcome.find(:first)

    cohort_report = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end)
    
#    @cohort_values = Hash.new(0) #Patient.empty_cohort_data_hash
    @cohort_values = Patient.empty_cohort_data_hash
    @cohort_values['messages'] = []

    @cohort_values['all_patients'] = cohort_report.patients_started_on_arv_therapy
    @cohort_values['male_patients'] = cohort_report.men_started_on_arv_therapy
    @cohort_values['female_patients'] = cohort_report.women_started_on_arv_therapy

    @cohort_values['adult_patients'] = cohort_report.adults_started_on_arv_therapy
    @cohort_values['child_patients'] = cohort_report.children_started_on_arv_therapy

    @cohort_values['occupations'] = cohort_report.occupations
    total_reported_occupations =  @cohort_values['occupations']['housewife'] + 
      @cohort_values['occupations']['farmer'] + @cohort_values['occupations']['soldier/police'] + 
      @cohort_values['occupations']['teacher'] + @cohort_values['occupations']['business'] + 
      @cohort_values['occupations']['healthcare worker'] + @cohort_values['occupations']['student']

    @cohort_values['occupations']['other'] = @cohort_values['all_patients'] - 
                                             total_reported_occupations
                                             
    # Reasons  for Starting
    # You can also use /reports/cohort_start_reasons
    start_reasons = cohort_report.start_reasons
    @cohort_values['start_reasons'] = start_reasons[0]
    @cohort_values["start_cause_EPTB"] = start_reasons[0]['start_cause_EPTB']
    @cohort_values["start_cause_PTB"] = start_reasons[0]['start_cause_PTB']
    @cohort_values["start_cause_APTB"] = start_reasons[0]['start_cause_APTB']
    @cohort_values["start_cause_KS"] = start_reasons[0]['start_cause_KS']
    @cohort_values["pmtct_pregnant_women_on_art"] = start_reasons[0]['pmtct_pregnant_women_on_art']


    # cohort_report.regimens is not working yet.
    # @cohort_values['regimens'] = cohort_report.regimens
    @cohort_values['regimen_types'] = cohort_report.regimen_types

    @cohort_values['1st_line_alternative_ZLN'] = @cohort_values["regimen_types"][1]["Nevirapine Zidovudine Lamivudine"]
    @cohort_values['1st_line_alternative_SLE'] = @cohort_values["regimen_types"][1]["Efavirenz Stavudine Lamivudine"]
    @cohort_values['1st_line_alternative_ZLE'] = @cohort_values["regimen_types"][1]["Efavirenz Zidovudine Lamivudine"]
                                                  
    @cohort_values['outcomes'] = cohort_report.outcomes
    @cohort_values['alive_on_ART_patients'] = @cohort_values['outcomes'][Concept.find_by_name('On ART').id]
    @cohort_values['dead_patients'] = @cohort_values['outcomes'][Concept.find_by_name('Died').id]
    @cohort_values['defaulters'] = @cohort_values['outcomes'][Concept.find_by_name('Defaulter').id]
    @cohort_values['art_stopped_patients'] = @cohort_values['outcomes'][Concept.find_by_name('ART Stop').id]
    @cohort_values['transferred_out_patients'] = @cohort_values['outcomes'][Concept.find_by_name('Transfer out').id] + 
                                                 @cohort_values['outcomes'][Concept.find_by_name('Transfer Out(With Transfer Note)').id] +
                                                 @cohort_values['outcomes'][Concept.find_by_name('Transfer Out(Without Transfer Note)').id]


    @cohort_values['side_effects'] = cohort_report.side_effects
    @cohort_values['ambulatory_patients'] = @cohort_values['side_effects'][Concept.find_by_name('Is able to walk unaided').id]
    @cohort_values['working_patients'] = @cohort_values['side_effects'][Concept.find_by_name('Is at work/school').id]

    @cohort_values['peripheral_neuropathy_patients'] = @cohort_values['side_effects'][Concept.find_by_name('Peripheral neuropathy').id] # + 
                                                       #@cohort_values['side_effects'][Concept.find_by_name('Leg pain / numbness').id]
    @cohort_values['hepatitis_patients'] = @cohort_values['side_effects'][Concept.find_by_name('Hepatitis').id] # + 
                                           # @cohort_values['side_effects'][Concept.find_by_name('Jaundice').id]
    @cohort_values['skin_rash_patients'] = @cohort_values['side_effects'][Concept.find_by_name('Skin rash').id]

    @cohort_values['on_1st_line_with_pill_count_adults'] = cohort_report.adults_on_first_line_with_pill_count
    @cohort_values['adherent_patients'] = cohort_report.adults_on_first_line_with_pill_count_with_eight_or_less

    death_dates = cohort_report.death_dates
    @cohort_values['died_1st_month'] = death_dates[0]
    @cohort_values['died_2nd_month'] = death_dates[1]
    @cohort_values['died_3rd_month'] = death_dates[2]
    @cohort_values['died_after_3rd_month'] = death_dates[3]
    

    # debug 
    @cohort_patient_ids = {:all => [],
                                 :occupations => {},
                                 :start_reasons => {},
                                 :outcome_data => {},
                                 :of_those_on_art => {},
                                 :of_those_who_died => {}
                           }
    @cohort_patient_ids[:all] = PatientRegistrationDate.find(:all, 
                                  :joins => 'LEFT JOIN patient_identifier ON  
                                             patient_identifier.patient_id = patient_registration_dates.patient_id 
                                             AND identifier_type = 18 AND voided = 0',
                                  :conditions => ["DATE(registration_date) >= ? AND DATE(registration_date) <= ?", 
                                                  @quarter_start, @quarter_end],
                                  :order => 'CONVERT(RIGHT(identifier, LENGTH(identifier)-3), UNSIGNED)').map(&:patient_id)

    @cohort_patient_ids[:start_reasons] = start_reasons[1] 
    @total_patients_text = "Patients ever started on ARV therapy"

    render :layout => false and return if params[:id] == "Cumulative" 
    
    @total_patients_text = "Patients started on ARV therapy in the last quarter"
#    survival_analysis
    render :layout => false
  end

  def cohort_start_reasons
    @cohort_values = Hash.new(0)
    @cohort_values['messages'] = []
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])
    
    start_reasons = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end).start_reasons
    @cohort_values['start_reasons'] = start_reasons[0]
    @cohort_values["start_cause_EPTB"] = start_reasons[0]['start_cause_EPTB']
    @cohort_values["start_cause_PTB"] = start_reasons[0]['start_cause_PTB']
    @cohort_values["start_cause_APTB"] = start_reasons[0]['start_cause_APTB']
    @cohort_values["start_cause_KS"] = start_reasons[0]['start_cause_KS']
    @cohort_values["pmtct_pregnant_women_on_art"] = start_reasons[0]['pmtct_pregnant_women_on_art']

    # debug 
    @cohort_patient_ids = {:all => [],
                                 :occupations => {},
                                 :start_reasons => {},
                                 :outcome_data => {},
                                 :of_those_on_art => {},
                                 :of_those_who_died => {}
                           }
    @cohort_patient_ids[:all] = PatientRegistrationDate.find(:all, 
                                  :joins => 'LEFT JOIN patient_identifier ON  
                                             patient_identifier.patient_id = patient_registration_dates.patient_id 
                                             AND identifier_type = 18 AND voided = 0',
                                  :conditions => ["registration_date >= ? AND registration_date <= ?", 
                                                  @quarter_start, @quarter_end], 
                                  :order => 'CONVERT(RIGHT(identifier, LENGTH(identifier)-3), UNSIGNED)').map(&:patient_id)

    @cohort_patient_ids[:start_reasons] = start_reasons[1] 

    render :layout => false
  end

  def cohort_art_regimens
    @cohort_values = Hash.new(0)
    @cohort_values['messages'] = []
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])

    regimen_types = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end).regimen_types
    @cohort_values['regimen_types'] = regimen_types[0]
    @cohort_values['regimen_breakdown'] = regimen_types[1]
    render :layout => false
  end

  def cohort_outcomes
    @cohort_values = Hash.new(0)
    @cohort_values['messages'] = []
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])

    @cohort_values['outcomes'] =  Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end).old_outcomes
    @cohort_values['alive_on_ART_patients'] = @cohort_values['outcomes']['alive_on_ART_patients']
    @cohort_values['dead_patients'] = @cohort_values['outcomes']['dead_patients']
    @cohort_values['defaulters'] = 0 #@cohort_values['outcomes']['defaulters']
    @cohort_values['art_stopped_patients'] = @cohort_values['outcomes']['art_stopped_patients']
    @cohort_values['transferred_out_patients'] = @cohort_values['outcomes']['transferred_out_patients']



    render :layout => false
  end

  def old_cohort
    redirect_to :action => 'select_cohort' and return if params[:id].nil?
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])  

    @quarter_start = Encounter.find(:first, :order => 'encounter_datetime').encounter_datetime.to_date if @quarter_start.nil?
		@quarter_end = Date.today if @quarter_end.nil?
	
#		Encounter.cache_encounter_regimen_names if Encounter.dispensation_encounter_regimen_names.blank?    

    @cohort_values = Patient.empty_cohort_data_hash
=begin
    @patients_with_visits_or_initiation_in_cohort = ActiveRecord::Base.connection.select_all("
SELECT DISTINCT patient.patient_id 
FROM patient
INNER JOIN encounter ON encounter.patient_id = patient.patient_id 
INNER JOIN (
   SELECT satisfied_ingredients.encounter_id as encounter_id, parent_concept.name as name FROM (
     SELECT count(*), encounter.encounter_id, regimen_ingredient.concept_id FROM encounter
     INNER JOIN orders ON orders.encounter_id = encounter.encounter_id
     INNER JOIN drug_order ON drug_order.order_id = orders.order_id
     INNER JOIN drug ON drug_order.drug_inventory_id = drug.drug_id
     INNER JOIN drug_ingredient as dispensed_ingredient ON drug.concept_id = dispensed_ingredient.concept_id
     INNER JOIN drug_ingredient as regimen_ingredient ON regimen_ingredient.ingredient_id = dispensed_ingredient.ingredient_id 
     INNER JOIN concept as regimen_concept ON regimen_ingredient.concept_id = regimen_concept.concept_id 
     WHERE encounter.encounter_type = 3 AND regimen_concept.class_id = 18 AND orders.voided = 0
     GROUP BY encounter.encounter_id, regimen_ingredient.concept_id, regimen_ingredient.ingredient_id) as satisfied_ingredients
    INNER JOIN concept_set AS parent_concept_set ON parent_concept_set.concept_id = satisfied_ingredients.concept_id
    INNER JOIN concept AS parent_concept ON parent_concept.concept_id = parent_concept_set.concept_set
    GROUP BY satisfied_ingredients.encounter_id, satisfied_ingredients.concept_id
    HAVING count(*) = (SELECT count(*) FROM drug_ingredient WHERE drug_ingredient.concept_id = satisfied_ingredients.concept_id)) as regimen ON regimen.encounter_id = encounter.encounter_id AND regimen.name = 'ARV First line regimen'
LEFT JOIN obs ON obs.encounter_id = encounter.encounter_id AND obs.concept_id = #{Concept.find_by_name('Date of ART initiation').id} 
GROUP BY patient_id, encounter_type
HAVING (encounter.encounter_type = #{EncounterType.find_by_name('Give drugs').id} AND MIN(DATE(encounter.encounter_datetime)) >= '#{@quarter_start.to_date}' AND MIN(DATE(encounter.encounter_datetime)) <= '#{@quarter_end.to_date}') 
    OR (MIN(DATE(obs.value_datetime)) >= '#{@quarter_start.to_date}' AND MIN(DATE(obs.value_datetime)) <= '#{@quarter_end.to_date}')
    ").map{|r|r["patient_id"]}
=end
#    i = 0
#    limit = 80
#    while (i < @patients_with_visits_or_initiation_in_cohort.length) do
#      @patients = Patient.find(:all, :include => [:patient_names, :patient_identifiers, :encounters], :conditions => ["patient.patient_id IN (?)", @patients_with_visits_or_initiation_in_cohort[i..i+limit-1]])
      @patients = Patient.find(:all, 
                            :joins => "INNER JOIN patient_registration_dates ON \
                                       patient_registration_dates.patient_id = patient.patient_id",
                            :conditions => ["registration_date >= ? AND registration_date <= ?", 
                                             @quarter_start, @quarter_end])

      @patients.each{|this_patient|
        @cohort_values = this_patient.cohort_data(@quarter_start, @quarter_end, @cohort_values)
      }
      #raise @cohort_values.to_yaml
#      i += limit
#    end
    #session[:cohort_patient_ids] = Report.cohort_patient_ids

		@cohort_values["side_effects_patients"] = @cohort_values["peripheral_neuropathy_patients"] + 
                                              @cohort_values["hepatitis_patients"] + 
		                                          @cohort_values["skin_rash_patients"] + 
                                              @cohort_values["lactic_acidosis_patients"] + 
														                  @cohort_values["lipodystropy_patients"] + 
                                              @cohort_values["anaemia_patients"] + 
                                              @cohort_values["other_side_effect_patients"]
   
    @survivals = nil
    @total_patients_text = "Patients ever started on ARV therapy"
    render :layout => false and return if params[:id] == "Cumulative" 
    
    @total_patients_text = "Patients started on ARV therapy in the last quarter"
    survival_analysis
    
    render :layout => false
  end

	def calculate_duplicate_data
	 	@pmtct_pregnant_women_on_art += 1 if @pmtct_pregnant_women_on_art_found
		
		@pmtct_pregnant_women_on_art_found = false
	end

  # Stand alone Survival Analysis page. use this to run Survival Analysis only, without cohort
  # e.g. http://bart/reports/survival_analysis/Q4+2007 
  #
  def survival_analysis
    redirect_to :action => 'select_cohort' and return if params[:id].nil?
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])  
    
    cohort_report = Reports::CohortByRegistrationDate.new(@quarter_start, @quarter_end)
    @survivals = cohort_report.survival_analysis

    @messages = []
    #render :text => @survivals.to_yaml
    render :layout => false
  end

  def old_survival_analysis
    redirect_to :action => 'select_cohort' and return if params[:id].nil?
    (@quarter_start, @quarter_end) = Report.cohort_date_range(params[:id])  

    @start_date = subtract_months(@quarter_end, 3) #@quarter_start
    @start_date -= @start_date.day - 1
    @end_date = @quarter_end
    @survivals = Array.new
    date_ranges = Array.new
    survival_patients = Array.new
    

    # TODO: Remove magic number 3. Loop til the very first quarter
    (1..3).each{ |i|
      @start_date = subtract_months(@start_date, 12)
      @start_date -= @start_date.day - 1
      @end_date = subtract_months(@end_date, 12)
      date_ranges << {:start_date => @start_date, :end_date => @end_date}
      survival_patients[i-1] = Array.new
    }
    all_patients = Patient.find(:all)
    all_patients.collect{|patient| 
      start_date = patient.date_started_art
      date_ranges.each_with_index{|date_range,i|
        if start_date and start_date.between?(date_range[:start_date].to_time, date_range[:end_date].to_time)
          survival_patients[i] << patient
          survival_patients[i].length
          break
        end
      }
    }
    (1..3).each{ |i|
      @survivals << Report.survival_analysis_hash(survival_patients[i-1], 
                                                  date_ranges[i-1][:start_date], 
                                                  date_ranges[i-1][:end_date], 
                                                  @quarter_end, i)
    }
    @survivals = @survivals.reverse
  end

  def reception
    @all_people_registered = Patient.find(:all, :conditions => "voided = 0")
    @total_people_registered_with_filing_numbers  = 0
    @all_people_registered.each{|person|
      @total_people_registered_with_filing_numbers += 1 unless person.filing_number.nil?
    }
    @people_registered_today = Patient.find(:all, :conditions => ["voided = 0 AND DATE(date_created) = ?", Date.today])
    @total_people_registered_with_filing_numbers_today = 0
    @people_registered_today.each{|person|
      @total_people_registered_with_filing_numbers_today += 1 unless person.filing_number.nil?
    }
  end
  
  def data
    @all_people_registered = Patient.find(:all, :conditions => "voided = 0")
    @total_people_registered_with_filing_numbers  = 0
    @all_people_registered.each{|person|
      @total_people_registered_with_filing_numbers += 1 unless person.filing_number.nil?
    }
    @people_registered_today = Patient.find(:all, :conditions => ["voided = 0 AND DATE(date_created) = ?", Date.today])
    @total_people_registered_with_filing_numbers_today = 0
    @people_registered_today.each{|person|
      @total_people_registered_with_filing_numbers_today += 1 unless person.filing_number.nil?
    }
  end
  
  def missed_appointments
     @patient_appointments = Patient.find(:all).collect{|pat|
      next if pat.date_started_art.nil?; 
      next if pat.outcome_status =~/Died|Transfer|Stop/; 
      next if pat.drug_orders.nil? or pat.drug_orders.empty?
      next if pat.next_appointment_date and pat.next_appointment_date.to_time > Date.today.to_time;
      pat
    }.compact
    render:layout => true;
  end

  def defaulters
    @defaulters = Patient.art_patients(:include_outcomes => [Concept.find_by_name("Defaulter")])
  end
  
  def select
    if params[:report]
      case  params[:report]
        when "Patient register"
           redirect_to :action => "virtual_art_register"
           return
        when "Cohort"
           redirect_to :action => "select_cohort"
           return
        when "Survival Analysis" #should this be hard coded? maybe use the most recently completed quarter, or just use today
           redirect_to :action => 'survival_analysis', :id => 'Q3+2008'
           return
        when "Missed appointments"
           redirect_to :action => "missed_appointments"
           return
        when "Defaulters"
           redirect_to :action => "defaulters"
           return
        when "Drug quantities"
           redirect_to :action => "select_monthly_drug_quantities"
           return
	#WTK
	when "Encounters by providers"
           redirect_to :action => "select_encounters_by_providers"
           return
	#WTK
      end
    end

   render:layout => "application";
  end

	def virtual_art_register
		# delete cache report if ?refresh appended to url
		#expire_page :action => "virtual_art_register" unless params[:refresh].nil? 

		@patients=Patient.virtual_register
		@i = @patients.length
		redirect_to :action =>"virtual_art_register" and return if @patients.nil?
		@quarter=(Time.now().month.to_f/3).ceil.to_s
		render(:layout => false)
  end
  
  def download_virtual_art_register
     @patients = Patient.virtual_register
     csv_string = FasterCSV.generate{|csv|
       csv<<["ARV #","Qrtr","Reg Date","Name","Sex","Age","Occupation","ART Start date","Start Reason","PTB","EPTB","KS","PMTCT","Outcome","Reg.","Ambulant","Work/School","Weight at Starting","Weight at last visit","Peripheral neuropathy","Hepatitis","Skin rash","Lactic acidosis"," Lipodistrophy","Anaemia","Other side effect","Remaining tablets"]
       counter = 0
       @patients.sort {|a,b| a[1].arv_registration_number[4..-1].to_i <=> b[1].arv_registration_number[4..-1].to_i }.each do |hash_key,visits | 
       counter += 1
       csv<<[visits.arv_registration_number,visits.quarter,visits.date_of_registration,visits.name,visits.sex, visits.age,visits.occupation, visits.date_of_art_initiation,visits.reason_for_starting_arv,visits.ptb, visits.eptb, visits.kaposissarcoma, visits.refered_by_pmtct,visits.outcome_status,visits.arv_regimen, visits.ambulant,  visits.at_work_or_school,visits.last_weight,visits.first_weight,visits.peripheral_neuropathy,visits.hepatitis,visits.skin_rash,visits.lactic_acidosis,visits.lipodystrophy,visits.anaemia,visits.other_side_effect,visits.tablets_remaining]
       end unless @patients.nil?
     
     }
     file_name ="#{Time.now}_virtual_patient_register.csv"
     send_data(csv_string,
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => file_name)
  end
  
  def pill_counts
    @patients = Patient.find(:all)
  end

  def select_monthly_drug_quantities
    if params[:report_year] and params[:report_month]
			redirect_to "/reports/monthly_drug_quantities/#{params[:report_year]}_#{params[:report_month]}"
      return 
    end
    render :layout => "application"
  end

  def monthly_drug_quantities
    year_month = []
    if params[:id].nil?
      redirect_to(:action => action_name, 
                  :id => "#{Date.today.year}_#{Date.today.month}")
      return
    end 
    year_month = params[:id].split("_") || nil
    @year = year_month[0].to_i || Date.today.year
    @month = year_month[1].to_i || Date.today.month

    @month_names = {1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May",
                    6 => "Jun", 7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct",
                    11 => "Nov", 12 => "Dec"}

    # create drug hash
    @drug_quantities = Hash.new
    Drug.find(:all).each{|drug|
      @drug_quantities[drug.name] = drug.month_quantity(@year, @month)
    }

    @drug_quantities = @drug_quantities.sort{|a,b| a[0] <=> b[0]}
  end

  def cohort_patients
  end

  def cohort_debugger
    #@patient_ids = Report.cohort_patient_ids[:all]
    cohort_patient_ids = params[:cohort_patient_ids] || session[:cohort_patient_ids] rescue nil
    @key = :all
    @field = ''

    if params[:cohort_patient_ids] #use all ids from params
      @key = params[:id].to_sym
      @field = params[:field]
      @patient_ids = cohort_patient_ids.split(',')
      @filter = params[:filter]
      return
    elsif params[:id] and params[:field] #extract from session
      @key = params[:id].to_sym
      @field = params[:field]
      @patient_ids = cohort_patient_ids[@key][@field] 
    elsif cohort_patient_ids
      @patient_ids = cohort_patient_ids[:all]
    else
      render :text => "Error: Could not get the list of patients to debug. <a href='javascript:history.back();'>Back</a>"
    end
  end

  def select_duplicate_identifiers
    render(:layout => "layouts/menu")
  end

  def duplicate_identifiers
    error_text = "Missing a Patient Identifier Type ID<br/>"
    error_text += "e.g. <a href='/reports/duplicate_identifiers/18'>Duplicate ARV Numbers</a>"
    render :action => 'select_duplicate_identifiers' and return if params[:id].nil?

    identifier_type = PatientIdentifierType.find(params[:id].to_i)
    @identifiers = PatientIdentifier.duplicates_by_type(identifier_type)
    @title = identifier_type.name
  end

  def select_missing_identifiers
    render(:layout => "layouts/menu")
  end

  def missing_identifiers
    error_text = "Missing a Patient Identifier Type ID<br/>"
    error_text += "e.g. <a href='/reports/missing_identifiers/18'>Missing ARV Numbers</a>"
    #render :text => error_text and return if params[:id].nil?
    render :action => 'select_missing_identifiers' and return if params[:id].nil?
    
    identifier_type = PatientIdentifierType.find(params[:id].to_i)
    @title = identifier_type.name
    
    hiv_program_id = Program.find_by_name('HIV').id
    art_patients = Patient.find(:all, :joins => [:programs], :conditions => ['patient_program.program_id = ? ', hiv_program_id])
    patients_with_identifier = Patient.find(:all, :joins => [:patient_identifiers], :conditions => ['patient_identifier.identifier_type = ?', identifier_type.id])
    @patients = art_patients - patients_with_identifier
  end

  def invalid_visits
    #
    # Needs a way to filter encounters e.g. by Qtr or month
    #
    dates = Encounter.find(:all, :select => 'DATE(encounter_datetime) as date', :group => 'DATE(encounter_datetime)').map(&:date)
    @patients_by_date = Hash.new([])
    dates.each{|date|
      @patients_by_date[date] << Encounter.invalid_visit_patients(date)
    }
  end

  def missing_visits
    (@start_date, @end_date) = Report.cohort_date_range(params[:id])  

    hiv_program_id = Program.find_by_name('HIV').id
    encounter_type_id = params[:type].to_i
    encounter_type_id = 3 if encounter_type_id < 1
    encounter_type = EncounterType.find(encounter_type_id) rescue nil
    @title = encounter_type.name rescue ''

    all_patients = Patient.find(:all, 
                                :joins => "INNER JOIN patient_program ON patient_program.patient_id = patient.patient_id
                                           INNER JOIN (SELECT patient_id, MIN(encounter_datetime) AS first_visit_date 
                                                       FROM encounter 
                                                       GROUP BY patient_id
                                                      ) AS first_encounters ON first_encounters.patient_id = patient.patient_id",
                                :conditions => ['patient.voided = ? AND patient_program.program_id = ? AND 
                                                 first_visit_date >= ? AND  
                                                 first_visit_date <= ?', 
                                                 0, 1, @start_date, @end_date], 
                                :group => 'patient_id')
    all_patients = all_patients.delete_if{|patient| patient.reason_for_art_eligibility.nil?}
    patients_without_drugs = encounter_type.encounters.find(:all, :group => 'patient_id').map(&:patient) rescue []
    @patients = all_patients - patients_without_drugs
  end

  def supervision
    render(:layout => "layouts/menu")
  end

end


