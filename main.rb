require 'open-uri'
require 'csv'
require './rates'

TRANS = 'https://puzzlenode.s3.amazonaws.com/attachments/1/TRANS.csv'
RATES = 'https://puzzlenode.s3.amazonaws.com/attachments/2/RATES.xml'
TARGET_ITEM = 'DM1182'

def parse_cost cost
  cost.split(' ')
end

def total_for_item item
  calc = RateCalculator.new
  calc.import_rates(RATES)
  
  total = 0.0
  rows = open(TRANS).read
  
  CSV.parse(rows, :headers => true) do |row|
    if row["sku"] == item
      orig_amount,currency = parse_cost row['amount']
  
      amount = calc.exchange(currency, "USD", orig_amount.to_f)
      
      total += amount
    end
  end
  
  total.round(2)
end

puts total_for_item(TARGET_ITEM)
