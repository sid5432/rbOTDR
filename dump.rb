#!/usr/bin/ruby
require 'json'

module Dump
  def self.jsonfile(results, opfile, format='JSON')
    
    File.open(opfile,"w") { |file|
      # puts results.to_json
      file.puts JSON.pretty_generate( results )
    }
  end
  
  def self.tracefile(trace, opfile, format='JSON')
    
    File.open(opfile,"w") { |file|
      trace.each { |str|
	file.puts str
      }
    }
  end
  
  
end
