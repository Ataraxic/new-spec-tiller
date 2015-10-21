require 'travis'

class TravisApi
  
  def initialize
    @client = Travis::Client.new('http://api.travis-ci.com');
    @client.github_auth(ENV.fetch('GITHUB_TOKEN_FOR_TRAVIS_API'))
    @repository = @client.repo(current_repo)
    
    raise 'Repo not found. Ensure Fetch URL of "git remote show origin" points to your repository' if repository.nil?

    
  end

  def get_build_log(branch)
    get_logs(most_recent_passed_build(branch))
  end

  private

  def most_recent_passed_build(branch)
    good_build = @repository.builds.select do |build|
      build.commit.branch == branch && build.state == 'passed'
    end.first
    
    good_build ? good_build : raise("No passing builds found for #{branch}")
  end

  def current_repo
    `git remote show -n origin`.match(/Fetch URL: .*:(.+).git/)[1]
  end

  def get_logs(build)
    build.
      jobs.
      map{ |j| j.log.body }.
      compact.
      join('\n')
  end
end
