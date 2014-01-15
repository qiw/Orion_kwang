# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Module: Utility
# Utility services for *Orion*.
#
# Module <Utility> provides utility services for the *Orion* project. Generally
# these are small methods that are handy for several purposes.

module Utility

  #============================================================================
  #
  # Instance methods
  #
  # These methods will be available as instance methods to any class that
  # includes <Utility>.
  #
  #============================================================================

  #----------------------------------------------------------------------------
  # Method: mergeResults
  # Merge two sets of results into one.
  #
  # Method <mergeResults> merges its second argument values and keys into the
  # its first argument. At the end, every key in the first argument will have
  # sum of values from the two results.

  def mergeResults(left, right)
    right.each_key { |k| left[k] += right[k] }
  end


  #============================================================================
  # Method: choose
  # Choose a random element of an *Array*.
  #
  # Method <choose> chooses a random element of an *Array*. If an empty *Array*
  # is supplied, an error is reported.

  def choose(a)
    errorExit("No elements in array") if a.empty?
    a[rand(a.length)]
  end


  #============================================================================
  # Method: gRand
  # Calculate a Gaussian random value.
  #
  # Method <gRand> generates a normally distributed random number (that is,
  # from the Gaussian distribution) given a mean (default 0) and standard
  # deviation (default 1). The method is taken from the Internet. Some small
  # and obvious corrections to the code presented there were made.
  #
  # Author - Matt Mower
  # From   - http://matt.blogs.it/entries/00002641.html
  # See    - http://www.taygeta.com/random/gaussian.html
  # See    - http://www.bearcave.com/misl/misl_tech/wavelets/hurst/random.html
  # 
  # Formal Parameters:
  #   mean   - the mean of the distribution. This value defaults to zero.
  #   stddev - the standard deviation of the distribution. This value defaults
  #             to one.
  #
  # Value:
  #   A random number distributed normally from a Gaussian distribution with
  #   the the given mean and standard deviation.
  #
  # Notes:
  #   - The mechanism uses (potentially) several calls to a uniform random
  #     number generator. This generator is reseeded by reseeding the
  #     underlying generator Kernel:rand using Kernel:srand.
  #
  # See Also:
  #   - Kernel:rand
  
  def gRand(mean = 0.0, stddev = 1.0)

    w = 10.0
    
    until w < 1.0
      x1 = 2.0*rand - 1.0
      x2 = 2.0*rand - 1.0
      w  = x1*x1 + x2*x2
    end

    w = Math.sqrt(-2.0*Math.log(w)/w)
    r = x1*w

    return mean + r*stddev

  end


  #============================================================================
  # Method: to_eval
  # Generate a "eval"-uable *String* from an *Array*
  #
  # Method <to_eval> takes an *Array* as input and generates an external
  # form that can be read and run by *eval()* to recreate the *Array*. The
  # value is in a *String* and, of course, it can be written easily.
  #
  # Formal Paramters:
  #   arr - an input *Array*
  #
  # Value:
  #   A *String* in a format that can be used to recreate the *Array*.
  #
  # Example:
  #   The output will look something like this.
  #     > [
  #     >     abc,  def, ghij,    k,   lm,  nop,   qr,  stu,    w,  xyz, # 10
  #     >    1234,   56,  890,   23, 2345,    7,  012,  843, 1235,   34, # 20
  #     >      ab, defg,   gh,
  #     > ]
  #
  # Notes:
  #   - The columns are arranged in groups of 10. Clearly, this could be
  #     modified.
  #   - The columns are sized to the largest element.
  #   - An index comment trails each row.
  #   - The "pretty" output is simplified because a *Ruby* *Array* may have a
  #     trailing comma without a problem.
  
  def to_eval(arr)

    # Find an appropriate length for the index format.

    len    = arr.length
    width  = Utility.numWidth(len)
    format = " # %#{width}d\n  "

    # Now do the same thing for the maximum column width.

    width = 0
    arr.each { |a| width = a.to_s.length if a.to_s.length > width }
    format2 = "%#{width}s, "

    # Pass through the array and write each element onto the string. Write an
    # index when it is needed. Tuck the closer on and return the string.

    str = "[\n  "
    0.upto(len - 1) do |i|
      str << format % i if i % 10 == 0 and i > 0
      str << format2 % arr[i].to_s
    end

    str << "\n]\n"

  end


  #============================================================================
  # Method: numWidth
  # Width of an integer for formatting.
  #
  # Method <numWidth> returns the number of decimal digits in its input. It
  # counts a digit for a minus sign and treats 0 as needing one digit.
  #
  # Arguments:
  #   num - an integer whose width is needed.
  #
  # Value:
  #   The number of decimal digits in the argument plus an extra if the number
  #   is negative.

  def Utility.numWidth(num)
    num = 1 if num == 0
    d = Math.log10(num.abs).floor.to_int + 1
    num < 0 ? d+1 : d
  end


  #============================================================================
  # Method: findSpecials
  # Finds "special" Oracle errors in a results *Hash*

  def findSpecials(results)

    # Get the keys from the results hash.

    theKeys = results.keys

    # For each key, see if it matches a special code. The key is a Symbol so
    # it needs to be converted to a String before the match. The special
    # code may not be all of the key which is why we use the matcher, not a
    # general equality. If we do get a hit, we remember how to get from the
    # old values to the new ones.

    old2New = Hash.new

    theKeys.each do |k|
      configuration.value(:specialCodes).each do |sc|
        old2New[k] = sc.to_sym if k.to_s.match(sc)
      end
    end

    # If we didn't find anything, then we can just return an empty Array of
    # the codes we did find.

    return Array.new if old2New.empty?

    # Now we use the old version of each code to generate the new version. To
    # make sure that we don't do something stupid when there was an exact 
    # match, we first do it out of line. The idea is to sum the results from
    # old matching codes into a new Hash, delete the old matches from the 
    # results Hash that came to use, and then to merge the new versions in.

    newResults = Hash.new(0)
    old2New.each_key { |k| newResults[old2New[k]] += results[k] }
    old2New.each_key { |k| results.delete(k) }
    results.merge!(newResults)
    
    # Finally, get all the distinct new codes that were used and then
    # return them to the caller. Notice that we want one instance of each.

    old2New.values.uniq

  end

end
