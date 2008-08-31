require 'open-uri'
require 'net/http'

require 'rubygems'
require 'json'

DM_URL = 'http://twitter.com/direct_messages.json?'
UPDATE_URL = 'http://twitter.com/statuses/update.json'

SINCE_ID_FILENAME = ".since_id"

@user = ARGV.shift
@password = ARGV.shift

def fetch_direct_messages(params = {})
  url = DM_URL.dup
  url << "since_id=" << params[:newer_than_id].to_s if params.has_key?(:newer_than_id)
  msgs = []
  open(url, :http_basic_authentication=>[@user, @password]) do |f|
    f.readline.each do |l|
      msgs << JSON.parse(l)
    end
  end
  msgs.flatten
end

def twitter(msg)
  url = URI.parse(UPDATE_URL)
  req = Net::HTTP::Post.new(url.path)
  req.basic_auth @user, @password
  req.set_form_data :status => msg
  Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
end

def since_id
  the_id = nil
  if File.exists? SINCE_ID_FILENAME
    open(SINCE_ID_FILENAME) { |f| the_id = f.readlines.last }
  end
  the_id
end

def store_id(since_id)
  open(SINCE_ID_FILENAME, "w") { f.write(since_id.to_s) }
end


loop do
  msgs = fetch_direct_messages :newer_than_id => since_id
  msgs.each do |msg|
    twitter "@#{msg['sender_screen_name']} says '#{msg['text']}'"
  end
  if msgs && !msgs.empty?
    last_msg_id = (msgs.max { |a, b| a["id"].to_i <=> b["id"].to_i })["id"]
    store_id(last_msg_id)
  end
  sleep 60
end