#!/usr/bin/ruby
$:.push File.dirname(__FILE__)
require 'parts'

def mapblock(fh,results, debug=false )
  
  fh.seek(0)
  
  tt = Parts::get_string(fh)
  if tt == 'Map' then
    results['format'] = 2
    if debug then
      $logger.info "MAIN: bellcore 2.x version"
    end
  else
    results['format'] = 1
    if debug then
      $logger.info "MAIN: bellcore 1.x version"
    end
    # rewind to start
    fh.seek(0)
  end
  
  # get version number
  results['version'] = "%.2f" % [0.01 * Parts::get_uint(fh,2)]
  
  # get number of bytes in map block
  results['mapblock'] = {};
  results['mapblock']['nbytes'] = Parts::get_uint(fh,4)
  
  if debug then
    $logger.info ("MAIN: Version %s, block size %d bytes; next position 0x%X" % 
      [ results['version'], results['mapblock']['nbytes'], fh.tell() ])
  end
  # get number of block; not including the Map block
  results['mapblock']['nblocks'] = Parts::get_uint(fh, 2) - 1
  
  if debug then
    $logger.info ("MAIN: %d blocks to follow; next position 0x%X" % 
      [results['mapblock']['nblocks'], fh.tell() ])
    $logger.info Parts::divider
  end
  
  # get block information
  if debug then
    $logger.info "MAIN: BLOCKS:"
  end
  
  results['blocks'] = {}
  startpos = results['mapblock']['nbytes']
  
  1.upto( results['mapblock']['nblocks'] ) { |i|
    bname = Parts::get_string(fh)
    bver  = "%.2f" % (Parts::get_uint(fh,2) * 0.01)
    bsize = Parts::get_uint(fh,4)
    
    ref = { 'name': bname, 'version': bver, 'size': bsize, 'pos': startpos, 'order': i-1 }
    results['blocks'][bname] = ref
    
    if debug then
      $logger.info "MAIN: %s block: version %s," % [bname, bver]
      $logger.info "block size %d bytes," % [bsize]
      $logger.info "start at pos 0x%X" % [startpos]
    end
    # start position of next block
    startpos += bsize
  }
  
  if debug then
    $logger.info Parts::divider
    $logger.info ("MAIN: next position 0x%X" % [fh.tell()])
    $logger.info Parts::divider
    $logger.info ""
  end
  
  return "ok"
end

