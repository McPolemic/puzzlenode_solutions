require 'bigdecimal'
require 'nokogiri'
require 'open-uri'

class BankerRound
  def self.round amount
    BigDecimal.new(amount.to_s).round(2, :banker)
  end
end

class RateCalculator
  def initialize
    @rates = {}
  end

  def import_rates url='https://puzzlenode.s3.amazonaws.com/attachments/4/SAMPLE_RATES.xml'
    doc = Nokogiri::XML(open(url))
    rates = doc.xpath('//rates/rate')
    rates.each do |rate_node|
      add_rate(rate_node.at_xpath('.//from').text,
               rate_node.at_xpath('.//to').text,
               rate_node.at_xpath('.//conversion').text.to_f)
    end
  end

  def add_rate from, to, rate
    @rates[from] = {} if @rates[from].nil?
    @rates[from][to] = rate
  end

  # Is the rate already set?
  def rate_outright_exists? from, to
    @rates[from] != nil && @rates[from][to] != nil
  end

  def rate from, to
    unless rate_outright_exists? from, to
      raise "Could not establish relationship from #{from} to #{to}!"
    end

    @rates[from][to] 
  end

  def exchange from, to, amount
    return amount if from == to
    
    path = rate_search([from], to)
    iterations = path.length - 1

    # For each pair, convert the amount and round
    iterations.times.each do |i|
      from_iter = path[i]
      to_iter = path[i + 1]
      exchange_rate = rate(from_iter, to_iter)
      amount = amount * exchange_rate
    end
    
    BankerRound.round(amount)
  end

  # Takes an array of the current chain and the target "to" currency
  # Returns an array of currencies that, in order, lead to the right
  # exchange rate
  def rate_search current, to
    head = current.first
    tail = current.last

    # Kick out early if we're repeating ourselves
    return nil if head == tail && current.length != 1

    # Does a direct relationship exist?
    if @rates[tail].keys.include? to
      return current + [to]
    end

    # Recurse into each key for the current tail to try and find a link
    # Returns nil if we couldn't find one, so we then delete all nil entries.
    chains = @rates[tail].keys.map do |key|
      new_chain = current + [key]
      chain = rate_search(new_chain, to)
    end.delete_if{|i| i.nil?}

    return chains.first unless chains.empty?

    return nil
  end
end


