module UsersHelper
  def user_data(user)
    return "" if user.nil?

    content_tag(:div, class: "user-data", title: user.full_name) do
      user.email
    end
  end
end
