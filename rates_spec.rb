require './spec_helper'

describe BankerRound do
  it "should round a currency to the same amount" do
    BankerRound.round(15.33).should eq 15.33
  end

  it "should round three decimal places below 0.50 down" do
    BankerRound.round(15.333).should eq 15.33
  end

  it "should round three decimals at 0.5 to the nearest even number" do
    BankerRound.round(15.335).should eq 15.34
    BankerRound.round(15.345).should eq 15.34
  end
end

describe RateCalculator do
  it "should accept a pair of currencies and a rate" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
  end

  it "should remember a pair of currencies and a rate" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.rate("AUD", "CAD").should eq 1.0079
  end

  it "can exchange currency for the same rate" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.exchange("AUD", "AUD", 14).should eq 14
  end

  it "can exchange currency for a remembered rate" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.exchange("AUD", "CAD", 14).should eq 14.11
  end

  it "should raise an exception if you try to span a relationship that doesn't exist" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    expect {
      calc.exchange("AUD", "USD", 14)
    }.to raise_error
  end

  it "can search for a one-hop relationship" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.rate_search(["AUD"], "CAD").should eq ["AUD", "CAD"]
  end

  it "can search for a two-hop relationship" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.add_rate("CAD", "USD", 1.0079)
    calc.rate_search(["AUD"], "USD").should eq ["AUD", "CAD", "USD"]
  end

  it "can search for a three-hop relationship" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.add_rate("CAD", "USD", 1.0079)
    calc.add_rate("USD", "EUR", 1.0079)
    calc.rate_search(["AUD"], "EUR").should eq %w{AUD CAD USD EUR}
  end

  it "can search without getting stuck in a circl" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.add_rate("CAD", "AUD", 1.0079)
    calc.add_rate("CAD", "USD", 1.0079)
    calc.add_rate("USD", "EUR", 1.0079)
    calc.rate_search(["AUD"], "EUR").should eq %w{AUD CAD USD EUR}
  end

  it "can span relationships" do
    calc = RateCalculator.new
    calc.add_rate("AUD", "CAD", 1.0079)
    calc.add_rate("CAD", "USD", 1.0090)
    calc.exchange("AUD", "USD", 14).should eq 14.24
  end

  it "should be able to import rates" do
    calc = RateCalculator.new
    calc.import_rates
    calc.exchange("AUD", "USD", 14).should eq 14.24
  end
end
