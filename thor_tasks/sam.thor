require 'ap'
require 'colorize'
require 'pathname'
require 'pp'
require 'terminal-table'
require 'thor'
require 'yaml'

require 'aws-sdk-cognitoidentityprovider'

# # USER_POOL_CLIENT_ID = 'ap-southeast-1_ZUtXUGFiV'.freeze
# # APP_CLIENT_ID       = '5kptplhu38d610jmh7ff9i2773'.freeze
# # APP_CLIENT_SECRET   = '17t704eb4cl1qrsv724bg6acv46edsmevdqmj7ji7hta0cnhb6r9'.freeze
# # USERNAME            = 'abcd'.freeze
# # SITE                = 'https://localhost:8800'
# # OAUTH_SERVER        = "https://ans-smsg--dev2.auth.ap-southeast-1.amazoncognito.com"
# GRAPHQL_ENDPOINT    = "https://jxijyfftjvebjgst7ye7djebzm.appsync-api.ap-southeast-1.amazonaws.com/graphql"

class Sam < Thor
  no_commands do
    def sha256_uuid
      Digest::SHA256.hexdigest(SecureRandom.base64)
    end
  end

  desc 'run-local FUNCTION_NAME', 'Sam operation'
  def run_local a_function_name
    require_relative './utils'

    sam_volume_path = Pathname.new(ENV.fetch('AWS_SAM_VOLUME_PATH'))#.join a_function_name
    puts sam_volume_path
    sam_local_port  = ENV.fetch "AWS_SAM_LOCAL_PORT_#{a_function_name}", '80'
    ap sam_volume_path
    envs = lambda_envs
    File.open(ENV_FILE, 'wb') { |f| f.write envs.to_json }
    ap envs
    cmd = \
      'sam local start-api '\
      "--port=#{sam_local_port} "\
      '--host=0.0.0.0 '\
      "--env-vars #{ENV_FILE} "\
      "-v #{sam_volume_path} "\
      "-t #{TEMPLATE_FILE}"

    puts cmd
    exec cmd
  end

  desc 'invoke-local LOGICAL_FUNCTION_NAME', 'Invoke local function'
  method_option :event, required: true
  def invoke_local a_function_name
    require_relative './utils'
    sam_volume_path = Pathname.new(ENV.fetch('AWS_SAM_VOLUME_PATH'))#.join a_function_name
    
    sam_local_port  = ENV.fetch "AWS_SAM_LOCAL_PORT_#{a_function_name}", '80'
    ap sam_volume_path
    envs = lambda_envs
    File.open(ENV_FILE, 'wb') { |f| f.write envs.to_json }
    ap envs

    event_file = Pathname.new options[:event]

    cmds = [
      'sam local invoke',
      "--env-vars #{ENV_FILE}",
      "-v #{sam_volume_path}",
      "-t #{TEMPLATE_FILE}",
    ]
    if event_file.file? && %w[.yml .yaml].include?(event_file.extname)
      tmpfile = event_file.dirname.join 'tmp', "#{event_file.basename}--#{sha256_uuid}.json"

      FileUtils.mkdir_p tmpfile.dirname unless tmpfile.dirname.directory?
      junkfiles = tmpfile.dirname.join('*')
      puts `rm -rf #{junkfiles}` if tmpfile.dirname.directory?

      json = JSON.pretty_generate YAML.load(event_file.read)
      tmpfile.write json
      cmds.push "--event=#{tmpfile}"
    else
      cmds.push "--event=#{event_file}"
    end

    cmds.push a_function_name

    puts cmds.join "\n"
    exec cmds.join ' '
  end
end
