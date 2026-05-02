class JournalCorrectionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @journal_corrections = current_user
                           .journal_corrections
                           .includes(:journal, :mistakes)
                           .joins(:journal)
                           .where(journals: { posted_date: Date.current.all_month })
                           .order("journals.posted_date DESC, journal_corrections.journal_id DESC")
  end

  def show
    @journal_correction = current_user
                          .journal_corrections
                          .includes(:mistakes, :journal)
                          .find(params[:id])

    current_journal_id = @journal_correction.journal_id
    @previous_journal_correction = current_user.journal_corrections.where("journal_id < ?", current_journal_id).order(journal_id: :desc).first
    @next_journal_correction = current_user.journal_corrections.where("journal_id > ?", current_journal_id).order(journal_id: :asc).first
  end
end
