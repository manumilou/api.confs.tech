class GithubController < ApplicationController
  before_action :assign_api_version

  rescue_from Octokit::UnprocessableEntity, Octokit::NotFound do |exception|
    render json: { status: exception.response_status, error: exception.message }
  end

  LATEST_VERSION = '2018-03-05'

  def index
    gh_wrapper = GithubWrapper.new
    result = gh_wrapper.list

    render json: result
  end

  def create
    gh_wrapper = GithubWrapper.new

    year = params[:year]
    domain = params[:domain]
    name = params[:name]
    url = params[:url]
    startDate = params[:startDate]
    branch = branch_name(name, url, startDate)
    filepath = guess_json_filepath(year, domain)

    file = gh_wrapper.pull_from_repo(filepath)
    
    new = gh_wrapper.update(file[:content], hash_to_submit)

    commit = gh_wrapper.create_commit(commit_message, file[:path], file[:sha], new, branch)

    result = gh_wrapper.create_pull_request(branch, commit_message)

    render json: result
  end

  private

  def assign_api_version
    byebug
    requested_version = if request.headers['Api-Version']
      request.headers['Api-Version']
    else
      LATEST_VERSION
    end
      
    if @current_user.api_version.nil? || request.headers['Api-Version']
      @current_user.api_version = requested_version
      @current_user.save
    end
    # Validate version format. It must correspond to an existing version
    # number defined in the master list. Then assign it to user
  end
  
  def commit_message
    "Add #{params[:name]} conference"
  end

  def branch_name(name, url, date)
    string = "#{name}-#{url}-#{date}"
    Digest::SHA2.hexdigest(string)[0..16]
  end
  
  def guess_json_filepath(year, domain)
    return false if year.blank? || domain.blank?

    "conferences/#{year}/#{domain}.json"
  end

  def hash_to_submit
    params.permit(:name, :url, :startDate, :endDate, :city, :country, :twitter).to_h
  end
end
