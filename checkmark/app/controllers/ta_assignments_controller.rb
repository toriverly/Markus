class TaAssignmentsController < ApplicationController

  before_filter :authorize

  # Grab the list of assignment to be marked
  def index
    @assignments = Assignment.all(:order => :id)
  end

  # List the submission for this assignment
  # For each submission, identify the groups
  # Recall that for individual assignments, each individual is a group of 1
  # TODO: test group submission, test individual submission
  def list

    # Find the assignment given the id
    @assignment = Assignment.find(params[:id])
    # Find all the groups for the assignment
    @groups = @assignment.groups.all(:include => [:memberships])
    
    memberships = @groups.map { |g| g.memberships }
    user_groups = memberships.flatten.map { |m| m.user.id }
    @students = User.students.index_by { |s| s.id }

    @tas = User.tas
        
  end

  # Assign a TA to the submissions
  # Allow for multple TAs to be assigned.
  def assign

    @ta = User.find_by_id(params[:ta_id])
    @selectedGroups = ActiveSupport::JSON.decode(params[:selected_groups])

    #output = { 'status' => 'OK', 'groups' => @selectedGroups }
    #render :json => output.to_json
    
    success = true
    numGroups = 0;
    
    @selectedGroups.each do |group|

      numGroups = numGroups + 1;
      ta_assignment = Grade.new
      ta_assignment.user_id = @ta
      ta_assignment.group_id = group
      if (!ta_assignment.save) then success = false end
    end

    if success
      output = {'status' => 'OK', 'groups' => @selectedGroups, 'numGroups' => numGroups}
    else
      output = {'status' => 'error'}
    end
    
    render :json => output.to_json
    
  end

  # Edit the TA for the assignments
  def edit
  end

end
