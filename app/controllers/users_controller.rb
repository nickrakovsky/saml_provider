# frozen_string_literal: true

class UsersController < ApplicationController

  before_action :set_company
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = @company.users.all
  end

  def show; end

  def new
    @user = @company.users.new
  end

  def edit; end

  def create
    @user = @company.users.new(user_params)

    if @user.save
      redirect_to @user, notice: "User was successfully created."
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: "User was successfully destroyed."
  end

  private

  def set_company
    @company = Company.first
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

end