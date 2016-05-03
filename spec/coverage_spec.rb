describe "coverage" do
  (Pathname(__dir__) + "../bin").children.each do |path|
    it "#{path.basename} has some tests" do
      expect(Pathname(__dir__) + "#{path.basename}_spec.rb").to exist
    end
  end
end
