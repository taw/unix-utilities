describe "coverage" do
  (Pathname(__dir__) + "../bin").children.each do |path|
    if (Pathname(__dir__) + "#{path.basename}_spec.rb").exist?
      # OK
    else
      pending "#{path.basename} has some tests"
    end
  end
end
