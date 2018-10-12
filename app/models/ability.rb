class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.nil?
    can :manage, :all if user.admin?
    can %i[create show], Agreement, user_id: user.id
    can %i[create show], Deposit, user_id: user.id
    can %i[update], EmailPreference, uni: user.uid
  end
end
