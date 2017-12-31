#!/usr/bin/ruby
require 'logger'

$:.push File.dirname(__FILE__)
require 'read'
require 'dump'

# ============== main ===========================
if __FILE__ == $0
  if ARGV.length < 1 then
    puts "USAGE: #{__FILE__} SOR-file"
    exit
  end

  otdrfile = ARGV[0]
  
  $logger = Logger.new(STDOUT)
  # $logger = Logger.new('logfile.txt');

  original_formatter = Logger::Formatter.new
  $logger.formatter = proc { |serverity, datetime, progrname, msg|
    # original_formatter.call(  serverity, datetime, progrname, msg.dump )
    # keep it simple for now:
    puts msg
  }
  
  sorparse = SORparse.new( otdrfile )
  results = {}
  trace = []
  sorparse.run(results, trace, debug=true)

  # construct data file name to dump results
  resultsfile = File.basename( otdrfile, ".*" )+"-dump.json"
  Dump::jsonfile(results, resultsfile)
  
  # construct data file name
  tracefile = File.basename( otdrfile, ".*" )+"-trace.dat"
  Dump::tracefile(trace, tracefile)
  
end  
