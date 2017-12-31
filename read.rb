#!/usr/bin/ruby
require 'logger'

$:.push File.dirname(__FILE__)
require 'parts'
require 'mapblock'
require 'genparams'
require 'supparams'
require 'fxdparams'
require 'datapts'
require 'keyevents'
require 'cksum'

class SORparse
  attr_reader :filename, :fh
  
  def initialize(filename)
    @filename = filename
    @fh = Parts::Sorfile.new(@filename)
    
    # default logger (if not already defined)
    if $logger == nil then
      $logger = Logger.new(STDOUT)
    end
    
    # final clean-up
    ObjectSpace.define_finalizer(self, proc { 
	# $logger.info "* close file"
	@fh.close()
      });
    
    # $logger.info "* init done"
  end
  
  # ---------------------------------------------
  # process the SOR file; results go into the results hash,
  # trace data go into the array trace[]
  def run(results,trace, debug=false)
    # trace[0] = 123
    results['filename'] = File.basename @filename
    status = mapblock(@fh,results,debug=debug)
    
    if status != 'ok' then
      return status
    end
    
    # go through the blocks --------------------
    klist = results['blocks'].sort_by { |k,v| v['order'] }
    klist.each { |k,ref|
      # puts "key is #{k}, #{ref[:order]}"
      bname = ref[:name]
      bsize = ref[:size]
      start = ref[:pos]
      
      if debug then
	$logger.info "MAIN: %s block: %d bytes, start pos 0x%X (%d)" % [bname, bsize, start, start]
      end
      
      if bname == 'GenParams' then
	status = Genparams::process(fh, results, debug=debug)
      elsif bname == 'SupParams' then
	status = Supparams::process(fh, results, debug=debug)
      elsif bname == 'FxdParams' then
	status = Fxdparams::process(fh, results, debug=debug)
      elsif bname == 'DataPts' then
	status = Datapts::process(fh, results, trace, debug=debug)
      elsif bname == 'KeyEvents' then
	status = Keyevents::process(fh, results, debug=debug)
      elsif bname == 'Cksum' then
	status = Cksum::process(fh, results, debug=debug)
      else
	Parts::slurp(fh, bname, results, debug=debug)
	status = 'ok'
      end	
      
      if debug then
	$logger.info "" 
      end
      
      # stop immediately if any errors
      if status != 'ok' then
	break
      end
    }
    return status
  end
  
end
