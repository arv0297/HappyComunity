# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_review, mutation: Mutations::CreateReview
    field :update_review, mutation: Mutations::UpdateReview
    field :delete_review, mutation: Mutations::DeleteReview
    field :ban_user, mutation: Mutations::BanUser
    field :unban_user, mutation: Mutations::UnbanUser
  end
end
