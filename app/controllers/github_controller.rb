class GithubController < ApplicationController
  rescue_from Octokit::UnprocessableEntity, Octokit::NotFound do |exception|
    render json: { status: exception.response_status, error: exception.message }
  end

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
