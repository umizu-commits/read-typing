class TypingResultPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && record.user == user
  end

  def update?
    user.present? && record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
