require 'pp'
require 'socket'
require 'ipaddr'
require 'net/http'

require 'http_scanner/version'

class HttpScanner
  def initialize
    @mutex = Mutex.new
    @results = []
    @queue = Queue.new
    @ip_range = current_ip_range
  end

  def scan(signature)
    addresses = get_ip_range(@ip_range[:ip_start], @ip_range[:ip_end])
    addresses.each do |address|
      @queue << address
    end
    threads = []

    255.times do
      threads << Thread.new do
        thread_results = scan_thread(@queue, signature)
        @mutex.synchronize do
          @results.concat(thread_results)
        end
      end
    end

    threads.each do |thread|
      begin
        thread.join
      rescue => e
        p "Thread Join Error: #{e}"
      end
    end
    @results
  end

  protected

  def current_ip_range
    ip_local = local_ip
    p '#####################################'
    p '#                                   #'
    p '#' + "YOUR IP: #{ip_local}".center(35) + '#'
    p '#                                   #'
    p '#####################################'
    ip = ip_local.split('.')
    ip_start = "#{ip[0]}.#{ip[1]}.#{ip[2]}.0"
    ip_end = "#{ip[0]}.#{ip[1]}.#{ip[2]}.255"
    {
      ip_start: ip_start,
      ip_end: ip_end
    }
  end

  def get_ip_range(start_ip, end_ip)
    start_ip = IPAddr.new(start_ip)
    end_ip = IPAddr.new(end_ip)
    (start_ip..end_ip).map(&:to_s)
  end

  def local_ip
    ip = Socket.ip_address_list.detect(&:ipv4_private?)
    ip.ip_address if ip
  end

  def scan_thread(queue, signature)
    results = []

    loop do
      addr = queue.pop(true)
      uri = URI.parse("http://#{addr}/")
      http = begin
        Net::HTTP.start(uri.host, uri.port,
                        read_timeout: 2,
                        open_timeout: 2)
      rescue
        nil
      end
      if http
        body = ''
        begin
          http.get('/') do |chunk|
            body += chunk
          end
        rescue
          nil
        end
        if body.include?(signature)
          print "!#{addr} "
          results << addr
        else
          print '*'
        end
        http.finish
      else
        print '.'
      end
    end
  rescue ThreadError
    results = results.uniq
    results
  end
end
