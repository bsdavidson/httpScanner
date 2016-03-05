require 'ipaddr'
require 'logger'
require 'net/http'
require 'socket'

require 'http_scanner/version'

class HttpScanner
  attr_writer :logger

  def initialize
    @mutex = Mutex.new
    @queue = Queue.new
    @results = []
  end

  def logger
    @logger ||= Logger.new(STDERR).tap do |logger|
      logger.progname = 'http_scanner'
    end
  end

  # Scans the local network and returns an array of IP addresses of systems that
  # return text containing the signature.
  #
  # @param signature [String] Case sensitive string to be searched for in the
  #   HTML of scanned systems.
  # @param opts [Hash] Additional options.
  # @option opts [Fixnum] :threads Size of the thread pool to use to scan the
  #   local network. Defaults to 255 threads.
  # @return [Array] IP addresses of systems with a positive match.
  def scan(signature, opts = {})
    ip_range = local_ip_range
    addresses = get_ips_in_range(ip_range[:ip_start], ip_range[:ip_end])
    addresses.each do |address|
      @queue << address
    end
    threads = []

    (opts[:threads] || 255).times do
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
        logger.error "Caught error in thread:"
        logger.error e
      end
    end
    @results
  end

  protected

  def local_ip_range
    ip_local = local_ip
    ip = ip_local.split('.')
    ip_start = "#{ip[0]}.#{ip[1]}.#{ip[2]}.1"
    ip_end = "#{ip[0]}.#{ip[1]}.#{ip[2]}.255"
    logger.debug "Local IP address: #{ip_local}"
    logger.debug "Local IP range: #{ip_start}...#{ip_end}"
    {
      ip_start: ip_start,
      ip_end: ip_end
    }
  end

  def get_ips_in_range(start_ip, end_ip)
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
        logger.debug('#{addr}: connection error')
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
          logger.debug "#{addr}: string found"
          results << addr
        else
          logger.debug "#{addr}: string not found"
        end
        http.finish
      end
    end
  rescue ThreadError
    results = results.uniq
    results
  end
end
