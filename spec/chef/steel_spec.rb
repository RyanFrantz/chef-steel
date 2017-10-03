require "spec_helper"

RSpec.describe Chef::Steel do
  it "has a version number" do
    expect(Chef::Steel::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
