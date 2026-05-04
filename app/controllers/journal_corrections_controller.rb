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
    @journal_correction = current_user.journal_corrections.includes(:mistakes, :journal).find(params[:id])
    @journal = @journal_correction.journal

    current_journal_id = @journal_correction.journal_id
    @previous_journal_correction = current_user.journal_corrections
                                  .joins(:journal)
                                  .where("journals.posted_date < ? OR (journals.posted_date = ? AND journals.id < ?)",
                                  @journal_correction.journal.posted_date, @journal_correction.journal.posted_date, @journal_correction.journal_id)
                                  .order("journals.posted_date DESC, journals.id DESC").first
    @next_journal_correction = current_user.journal_corrections
                               .joins(:journal)
                               .where("journals.posted_date > ? OR (journals.posted_date = ? AND journals.id > ?)",
                               @journal_correction.journal.posted_date, @journal_correction.journal.posted_date, @journal_correction.journal_id)
                               .order("journals.posted_date ASC, journal_corrections.journal_id ASC").first
  end
end
