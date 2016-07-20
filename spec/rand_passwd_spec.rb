describe "since_soup" do
  let(:binary) { Pathname(__dir__)+"../bin/rand_passwd" }

  it "generates random different strings" do
    passwords = 10.times.map{`#{binary}`.chomp}
    expect(passwords.size).to eq(passwords.uniq.size)
    passwords.each do |password|
      expect(password).to match(/\A[a-z]{12}\z/)
    end
  end
end
