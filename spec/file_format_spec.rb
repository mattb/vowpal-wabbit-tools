require 'spec_helper'

# test specs based on examples from http://hunch.net/~vw/validate.html 
# and specification at https://github.com/JohnLangford/vowpal_wabbit/wiki/Input-format
describe VowpalWabbit::Fileformat do
  describe "parse lines" do
    it "works on a basic line" do
      parsed = VowpalWabbit::Fileformat.parse_line("1 1.0 |MetricFeatures:3.28 height:1.5 length:2.0 |Says black with white stripes |OtherFeatures NumberOfLegs:4.0 HasStripes")
      parsed[:label].should eq "1"
      parsed[:importance].should eq 1.0
      parsed[:tag].should eq ""
      parsed[:features][0][:namespace].should eq ["MetricFeatures", 3.28]
      parsed[:features][0][:features].should eq [["height", 1.5], ["length", 2.0]]
    end
    it "works on a very basic line" do
      parsed = VowpalWabbit::Fileformat.parse_line("0 a| a:2")
      parsed[:label].should eq "0"
      parsed[:importance].should eq 1.0
      parsed[:tag].should eq "a"
      parsed[:features][0][:namespace].should eq [nil, 1]
      parsed[:features][0][:features].should eq [["a", 2]]
    end
    it "copes with numeric features" do
      parsed = VowpalWabbit::Fileformat.parse_line("0 | price:.23 sqft:.25 age:.05 2006")
      parsed[:label].should eq "0"
      parsed[:importance].should eq 1
      parsed[:tag].should eq ""
      parsed[:features][0][:namespace].should eq [nil, 1]
      parsed[:features][0][:features].should eq [["price", 0.23], ["sqft", 0.25], ["age", 0.05], [2006, 1]]
    end
    it "should recognise the ' character in tags correctly" do
      parsed = VowpalWabbit::Fileformat.parse_line("1 2 'second_house| price:.18 sqft:.15 age:.35 1976")
      parsed[:label].should eq "1"
      parsed[:importance].should eq 2
      parsed[:tag].should eq "second_house"
      parsed[:features][0][:namespace].should eq [nil, 1]
      parsed[:features][0][:features].should eq [["price", 0.18], ["sqft", 0.15], ["age", 0.35], [1976, 1]]
    end
  end
  describe "generate lines" do
    it "should generate a basic line" do
      generated = VowpalWabbit::Fileformat.generate_line({:label=>"1", :importance=>2.0, :tag=>"second_house", :features=>[{:namespace=>[nil, 1], :features=>[["price", 0.18], ["sqft", 0.15], ["age", 0.35], [1976, 1]]}]})
      generated.should eq "1 2.0 'second_house| price:0.18 sqft:0.15 age:0.35 1976:1"
    end
    it "should generate a very basic line" do
      generated = VowpalWabbit::Fileformat.generate_line({:label=>"0", :importance=>1, :tag=>"a", :features=>[{:namespace=>[nil, 1], :features=>[["a", 2.0]]}]})
      generated.should eq "0 'a| a:2.0"
    end
  end
  describe "round-trip" do
    it "should round-trip from data to data" do
      data = {:label=>"1", :importance=>2.0, :tag=>"second_house", :features=>[{:namespace=>[nil, 1], :features=>[["price", 0.18], ["sqft", 0.15], ["age", 0.35], [1976, 1]]}]}
      VowpalWabbit::Fileformat.parse_line(VowpalWabbit::Fileformat.generate_line(data)).should eq data
    end
    it "should round-trip from line to line" do
      line = "1 2.0 'second_house| price:0.18 sqft:0.15 age:0.35 1976:1.0 |Foo:2.0 a:1.0"
      VowpalWabbit::Fileformat.generate_line(VowpalWabbit::Fileformat.parse_line(line)).should eq line
    end
  end
end
