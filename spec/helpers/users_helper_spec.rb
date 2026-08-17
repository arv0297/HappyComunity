require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the UsersHelper. For example:
#
# describe UsersHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe UsersHelper, type: :helper do
  describe 'User email plus name in title' do
    it 'returns an empty string if user is nil' do
      expect(user_data(nil)).to eq('')
    end

    it 'returns the user email inside a div with the full name as title' do
      user = User.new(
        name: 'John',
        last_name: 'Doe',
        second_last_name: 'Smith',
        email: 'john@example.com'
      )

      result = helper.user_data(user)

      expect(result).to include('john@example.com')
      expect(result).to include('title="John Doe Smith"')
      expect(result).to include('class="user-data"')
    end
  end
end
