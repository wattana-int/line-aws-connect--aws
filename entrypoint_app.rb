require '/docker-entrypoint/common.rb'

def main
  # create_prod_user home: \"/data/#{'PROD_USER_NAME'}\"
  thor_tasks
  compile [
    { src: '/app/supervisord.conf.erb', dst: '/supervisord.conf' }
  ]
end

if $PROGRAM_NAME == __FILE__
  main
  main_exec do
    'supervisord -c /supervisord.conf'
  end
end
