class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :update, User, id: user.id
    can :update, Account, id: user.account_id

    can :connect, :dropbox

    can [:read, :create, :destroy, :check, :archive, :send], Invoice, account_id: user.account_id
    can :update, Invoice do |invoice|
      %i(created charged).include?(invoice.state.to_sym) && invoice.account_id == user.account_id
    end
    can :pay, Invoice do |invoice|
      %i(charged).include?(invoice.state.to_sym) && invoice.account_id == user.account_id
    end
    can :charge, Invoice do |invoice|
      %i(created).include?(invoice.state.to_sym) && invoice.account_id == user.account_id
    end

    can :manage, Customer, account_id: user.account_id
    can :manage, Project, customer: { account_id: user.account_id }
    can :manage, Week, account_id: user.account_id
    can :manage, Task, project: { customer: { account_id: user.account_id } }
    can :manage, Timer, week: { account_id: user.account_id }

    if user.admin?
      can :manage, Account
      can :manage, User
    end
  end
end
