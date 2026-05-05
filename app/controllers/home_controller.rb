class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    # @journals = current_user.journals.order(posted_date: :desc).limit(3)
    @journals = current_user.journals.includes(:mistakes, :journal_correction).order(posted_date: :desc, id: :desc).limit(3)
    @total_count = current_user.total_journal_count
    @monthly_count = current_user.this_month_journal_count
    @total_learning_count = current_user.total_learning_count
    @monthly_learning_count = current_user.this_month_learning_count
    @streak_count = current_user.streak_dates
  end
end
