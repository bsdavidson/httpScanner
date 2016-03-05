require 'spec_helper'

describe HttpScanner do
  it 'has a version number' do
    expect(HttpScanner::VERSION).not_to be nil
  end

  it 'can find the local IP address' do
    expect(Socket).to receive(:ip_address_list).and_return [
      Addrinfo.ip('8.8.8.8'),
      Addrinfo.ip('10.0.0.1')
    ]
    http_scanner = HttpScanner.new
    expect(http_scanner.send(:local_ip)).to eq('10.0.0.1')
  end

  it 'can find the local IP range' do
    http_scanner = HttpScanner.new
    http_scanner.logger.level = Logger::INFO
    expect(http_scanner).to receive(:local_ip).and_return '10.0.0.40'
    expect(http_scanner.send(:local_ip_range)).to eq(ip_start: '10.0.0.1',
                                                     ip_end: '10.0.0.255')
  end

  it 'can expand two IPs into a range' do
    http_scanner = HttpScanner.new
    ips = http_scanner.send(:get_ips_in_range, '10.0.0.1', '10.0.0.255')
    expected_ips = (IPAddr.new('10.0.0.1')..IPAddr.new('10.0.0.255')).map &:to_s
    expect(ips).to eq(expected_ips)
  end

  it 'will find hosts matching the search string' do
    # hosts without a match should be ignored
    http_no_match = instance_double(Net::HTTP)
    expect(http_no_match).to receive(:get).with('/')
    expect(http_no_match).to receive(:finish)
    expect(Net::HTTP).to receive(:start).with(
      '169.254.1.1', 80, read_timeout: 2, open_timeout: 2).and_return(
      http_no_match)

    # hosts with a match should be returned
    http_match = instance_double(Net::HTTP)
    expect(http_match).to receive(:get).with('/').and_yield('foo')
    expect(http_match).to receive(:finish)
    expect(Net::HTTP).to receive(:start).with(
      '169.254.1.2', 80, read_timeout: 2, open_timeout: 2).and_return(
      http_match)

    # hosts with connection errors should be ignored
    expect(Net::HTTP).to receive(:start).with(
      '169.254.1.3', 80, read_timeout: 2, open_timeout: 2).and_raise(
      Timeout::Error)

    # hosts where raises an exception should be ignored
    http_invalid = instance_double(Net::HTTP)
    expect(http_invalid).to receive(:get).with('/').and_raise(Timeout::Error)
    expect(http_invalid).to receive(:finish)
    expect(Net::HTTP).to receive(:start).with(
      '169.254.1.4', 80, read_timeout: 2, open_timeout: 2).and_return(
      http_invalid)

    # hosts where match is split across chunks should be returned
    http_split = instance_double(Net::HTTP)
    expect(http_split).to receive(:get).with('/').and_yield(
      'xxfo').and_yield('oxx')
    expect(http_split).to receive(:finish)
    expect(Net::HTTP).to receive(:start).with(
      '169.254.1.5', 80, read_timeout: 2, open_timeout: 2).and_return(
      http_split)

    queue = Queue.new
    queue << '169.254.1.1'
    queue << '169.254.1.2'
    queue << '169.254.1.3'
    queue << '169.254.1.4'
    queue << '169.254.1.5'

    http_scanner = HttpScanner.new
    http_scanner.logger.level = Logger::INFO
    results = http_scanner.send(:scan_thread, queue, 'foo')
    expect(results).to eq(['169.254.1.2', '169.254.1.5'])
  end

  it 'will scan a range of hosts for a search string' do
    http_scanner = HttpScanner.new
    queue = http_scanner.instance_variable_get(:@queue)
    http_scanner.logger.level = Logger::INFO
    expect(http_scanner).to receive(:local_ip).and_return '169.254.1.1'
    expect(http_scanner).to receive(:scan_thread).with(queue, 'foo').and_return(
      ['169.254.1.100'], ['169.254.1.200'])

    results = http_scanner.scan('foo', threads: 2)
    expect(results).to eq(['169.254.1.100', '169.254.1.200'])
  end
end
