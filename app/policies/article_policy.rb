class ArticlePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def destroy?
    user.present? && record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end

  def favorite?
    user.present? && record.user == user
  end
end
