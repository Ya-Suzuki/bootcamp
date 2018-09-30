class AnnouncementsController < ApplicationController
  before_action :require_admin_login, except: %i(index show)

  def index
    @announcements = Announcement.all.order(created_at: :desc)
  end

  def show
    @announcement = Announcement.find(params[:id]) #set_announcementに書き換えたい
  end

  def new
    @announcement = Announcement.new
  end

  def edit
    @announcement = Announcement.find(params[:id])
    @announcement.user = current_user
  end

  def update
    @announcement = Announcement.find(params[:id])
    if @announcement.update(announcement_params)
      redirect_to @announcement, notice: t("announcement_was_successfully_updated")
    else
      render :edit
    end
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.user_id = current_user.id
    if @announcement.save
      redirect_to @announcement, notice: t("announcement_was_successfully_created")
    else
      render :new
    end
  end
  
  def destroy
    @announcement = Announcement.find(params[:id])
    @announcement.destroy
    redirect_to announcements_path, notice: "お知らせを削除しました"
  end

  private
    def announcement_params
     params.require(:announcement).permit(:title, :description, :user_id)
    end
end
