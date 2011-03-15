# Natrix is a named matrix
#
# Copyright 2009 ePark Labs, Inc. <http://eparklabs.com/>
# Author: Dan Fitzpatrick
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   
#     http://www.apache.org/licenses/LICENSE-2.0
#       
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# t = Natrix.new(
#   :xs => %w(a b c d), 
#   :ys => %w(m n o p)
# )
# t.set('a','p',20)
# t.get('a','p') => 20
# t.get(0,3) => 20
class Natrix
  include Enumerable
  # X Axis
  attr_accessor :xs
  # Y Axis
  attr_accessor :ys
  # Data
  attr_accessor :d
  # Mode (open|strict) 
  # Strict ensures that you can not set() or get() if the keys do not exist.
  attr_accessor :mode
  
  def initialize(a={},&b)
    @mode = 'open'
    @d = Hash.new
    @xs = Array.new
    @ys = Array.new
    a.each{|k,v| send("#{k}=",v)}
    yield self if b
  end
  
  # Make the keys strings
  def xs=(*args)
    @xs = args.flatten.map{|a| a.to_s}
  end
  
  def ys=(*args)
    @ys = args.flatten.map{|a| a.to_s}
  end
  
  # The x key
  def xk(key)
    return key.to_s if String === key or Symbol === key
    xs[key] # integer index
  end
  
  # The y key
  def yk(key)
    return key.to_s if String === key or Symbol === key
    ys[key] # integer index
  end
  
  def validate_input(x,y)
    # Validate input if strict mode
    if mode.to_s == 'strict'
      raise ArgumentError, "No X axis with a value of #{x.inspect}" unless 
            xs.include?(xk(x))
      raise ArgumentError, "No Y axis with a value of #{y.inspect}" unless 
            ys.include?(yk(y))
    end
  end
  
  # Set a value
  def set(x,y,val)
    # Validate input if strict mode
    validate_input(x,y) if mode.to_s == 'strict'
    d[xk(x)] ||= Hash.new
    d[xk(x)][yk(y)] = val
  end
  
  # Set a value
  def []=(x,y,val)
    set(x,y,val)
  end
  
  # Get a value
  def get(x,y)
    # Validate input if strict mode
    validate_input(x,y) if mode.to_s == 'strict'
    d[xk(x)][yk(y)] rescue nil
  end
  
  # Get a value with two args, get a row with 1 arg, empty with no args
  def [](x=nil,y=nil)
    return nil if x.nil? and y.nil?
    if y.nil?
      re = []
      each_y(x){|v| re << v}
      return re
    end
    get(x,y)
  end
  
  # Each returns all the values x0y0, x1y0, x2y0, x0y1, x1y1, x2y1...
  def each(&b)
    ys.each{|y| 
      xs.each{|x| 
        begin
          yield d[x][y]
        rescue
          yield nil 
        end
      }
    }
  end
  
  # Each X yields an array of values for an x column
  def each_x(x,&b)
    ys.each{|y| 
      begin
        yield d[xk(x)][y]
      rescue
        yield nil
      end
    }
  end
  
  # Each Y yields all the values for a y row
  def each_y(y,&b)
    xs.each{|x| 
      begin
        yield d[x][yk(y)] 
      rescue 
        yield nil
      end
    }
  end
  
  # Each Y A yields an Array of values for each row/y
  def each_ya
    ys.map{|y| 
      yield xs.map{|x| 
        d[x][y] rescue nil
      }
    }
  end
  
  # Each Y A yields an Array of values for each row/y
  def each_ya_with_index
    i = 0
    ys.map{|y| 
      yield xs.map{|x| 
        d[x][y] rescue nil
      }, i
      i += 1
    }
  end
  
  # Each Y A yields a hash of values for each row/y
  def each_yh
    ys.map{|y| 
      h = Hash.new
      xs.map{|x| 
        h[x] = d[x][y] rescue nil
      }
      yield h
    }
  end
  
  # Each Y A yields a hash of values for each row/y
  def each_yh_with_index
    i = 0
    ys.map{|y| 
      h = Hash.new
      xs.map{|x| 
        h[x] = d[x][y] rescue nil
      }
      yield h, i
      i += 1
    }
  end
  
  # Each X A yields an Array of values for each column/x
  def each_xa
    xs.map{|x| 
      yield ys.map{|y| 
        d[x][y] rescue nil
      }
    }
  end
  
  # Each X A yields an Array of values for each column/x
  def each_xa_with_index
    i = 0
    xs.map{|x| 
      yield ys.map{|y| 
        d[x][y] rescue nil
      },i
      i += 1
    }
  end
  
  # Output delimted text
  def to_delimited(x_delimiter="\t",y_delimiter="\n")
    ys.map{|y| 
      xs.map{|x| 
        d[x][y] rescue nil
      }.join(x_delimiter)
    }.join(y_delimiter)
  end
  
  # Build data from delimited text
  def from_delimited(data,x_delimiter="\t",y_delimiter="\n")
    data.split(y_delimiter).each_with_index{|line,y| 
      line.split(x_delimiter).each_with_index{|cell,x|
        begin
          d[xs[x]][ys[y]] = cell
        rescue
          d[xs[x]] ||= Hash.new
          d[xs[x]][ys[y]] = cell
        end
      }
    }
  end
  
  # Build data from delimited text
  def from_array(data)
    data.each_with_index{|line,y| 
      line.each_with_index{|cell,x|
        begin
          d[xs[x]][ys[y]] = cell
        rescue
          d[xs[x]] ||= Hash.new
          d[xs[x]][ys[y]] = cell
        end
      }
    }
  end
  
  def to_ah
    ys.map{|y| 
      h = Hash.new
      xs.map{|x| 
        h[x] = d[x][y] rescue nil
      }
      h
    }
  end
  
  def to_aa
    ys.map{|y| 
      xs.map{|x| 
        d[x][y] rescue nil
      }
    }
  end
  
  # Output a json array of hashes (You need to require json for this to work)
  def to_json_ah
    "[#{ys.map{|y| 
      "{#{xs.map{|x| 
        "#{x.to_json}: #{(d[x][y] rescue nil).to_json}"
      }.join(",")}}"
     }.join(",")}]"
  end
  
  # Output a json array of arrays (You need to require json for this to work)
  def to_json_aa
    "[#{ys.map{|y| 
      "[#{xs.map{|x| 
        (d[x][y] rescue nil).to_json
      }.join(",")}]"
     }.join(",")}]"
  end

  def size
    ys.size
  end

  def empty?
    size == 0
  end
  
end