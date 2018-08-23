require 'ap'
require 'colorize'
require 'pathname'
require 'pp'
require 'terminal-table'
require 'thor'

require 'aws-sdk-cognitoidentityprovider'

# # USER_POOL_CLIENT_ID = 'ap-southeast-1_ZUtXUGFiV'.freeze
# # APP_CLIENT_ID       = '5kptplhu38d610jmh7ff9i2773'.freeze
# # APP_CLIENT_SECRET   = '17t704eb4cl1qrsv724bg6acv46edsmevdqmj7ji7hta0cnhb6r9'.freeze
# # USERNAME            = 'abcd'.freeze
# # SITE                = 'https://localhost:8800'
# # OAUTH_SERVER        = "https://ans-smsg--dev2.auth.ap-southeast-1.amazoncognito.com"
# GRAPHQL_ENDPOINT    = "https://jxijyfftjvebjgst7ye7djebzm.appsync-api.ap-southeast-1.amazonaws.com/graphql"

class Cf < Thor
  no_commands do
    def sha256_uuid
      Digest::SHA256.hexdigest(SecureRandom.base64)
    end
  end

  desc 'deploy', 'Cloudformation deployment'
  def deploy
    templatefile = '/app/template.yml'
    stack_name = ENV.fetch 'STACK_NAME'
    cmd = "/app/bin/app deploy #{sha256_uuid} #{stack_name} #{templatefile}"
    puts '--'
    puts cmd
    exec cmd
  end
end
